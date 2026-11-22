# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:audit) { described_class.new(env) }
  let(:audit_topic) { create_topic }
  let(:env) { { "REMOTE_ADDR" => "10.0.0.1", "HTTP_USER_AGENT" => "agent/1.0" } }
  let(:call_id) { SecureRandom.uuid }
  let(:arguments) { { "limit" => 5 } }
  let(:records) do
    Karafka.producer.client.flush

    Karafka::Admin
      .read_topic(audit_topic, 0, 100)
      .map { |message| JSON.parse(message.raw_payload) }
  end
  let(:record) { records.last }

  before { Karafka::Web.config.topics.mcp_audit.name = audit_topic }

  after { Karafka::Web.config.mcp.audit.actor = nil }

  describe "#result" do
    before do
      audit.result(
        call_id,
        "karafka_errors_list",
        arguments,
        outcome: "ok",
        sync: false,
        started_at: audit.monotonic_now - 10,
        summary: { "errors" => 2 }
      )
    end

    it "writes one record with the call details" do
      assert_equal(1, records.size)
      assert_equal("1.0.0", record["schema_version"])
      assert_equal("result", record["type"])
      assert_equal(call_id, record["call_id"])
      assert_equal(call_id, Karafka::Admin.read_topic(audit_topic, 0, 1).first.key)
      refute_equal(call_id, record["id"])
      assert_equal("karafka_errors_list", record["tool"])
      assert_equal({ "limit" => 5 }, record["arguments"])
      assert_equal("ok", record["outcome"])
      assert_nil(record["error"])
      assert_operator(record["duration"], :>=, 10)
      assert_equal({ "errors" => 2 }, record["summary"])
      assert_in_delta(Time.now.to_f, record["dispatched_at"], 60)
    end

    it "uses the remote IP and User-Agent as the actor" do
      assert_equal({ "remote_ip" => "10.0.0.1", "user_agent" => "agent/1.0" }, record["actor"])
    end
  end

  describe "#intent" do
    it "writes the record" do
      assert(audit.intent(call_id, "karafka_test_change", arguments))
      assert_equal("intent", record["type"])
      assert_equal(call_id, record["call_id"])
      refute(record.key?("outcome"))
    end

    it "waits for the write on an acks: all producer" do
      producer = Karafka::Web.producers.fully_acked

      assert_equal("all", producer.topic_config[:acks])

      producer.expects(:produce_sync).once
      Karafka::Web.producers.default.expects(:produce_async).never

      assert(audit.intent(call_id, "karafka_test_change", arguments))
    end
  end

  describe "#result" do
    context "when sync" do
      it "waits for the write on an acks: all producer" do
        Karafka::Web.producers.fully_acked.expects(:produce_sync).once
        Karafka::Web.producers.default.expects(:produce_async).never

        assert(audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: true))
      end
    end

    context "when async" do
      it "hands the write over to the default producer" do
        Karafka::Web.producers.default.expects(:produce_async).once
        Karafka::Web.producers.fully_acked.expects(:produce_sync).never

        assert(audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: false))
      end
    end
  end

  context "when actor callable raises" do
    let(:events) { [] }

    before do
      Karafka::Web.config.mcp.audit.actor = ->(_rack_env) { raise ArgumentError }
      Karafka.monitor.stubs(:instrument).with { |_name, payload| events << payload[:type] }
    end

    it "writes the result with the request actor and the error class" do
      assert(audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: false))
      assert_equal(
        { "remote_ip" => "10.0.0.1", "user_agent" => "agent/1.0", "actor_error" => "ArgumentError" },
        record["actor"]
      )
      assert_includes(events, "web.mcp.audit.error")
    end

    it "writes but reports a sync result as failed" do
      refute(audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: true))
      assert_equal("ArgumentError", record.dig("actor", "actor_error"))
    end

    it "refuses the intent and writes the rejection" do
      refute(audit.intent(call_id, "karafka_test_change", arguments))
      assert_equal(1, records.size)
      assert_equal("result", record["type"])
      assert_equal(call_id, record["call_id"])
      assert_equal("rejected", record["outcome"])
      assert_equal("Actor could not be resolved", record["error"])
      assert_equal("ArgumentError", record.dig("actor", "actor_error"))
    end
  end

  context "when arguments hold credentials and large values" do
    let(:arguments) do
      {
        "sasl.password" => "secret",
        "nested" => { "ssl.key.password" => "secret", "name" => "visible" },
        "payload" => "a" * 5_000,
        "keys" => (1..200).to_a
      }
    end

    before { audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: true) }

    it "masks the credentials and cuts the large values" do
      written = record["arguments"]

      assert_equal("***", written["sasl.password"])
      assert_equal({ "ssl.key.password" => "***", "name" => "visible" }, written["nested"])
      assert_equal(1_027, written["payload"].size)
      assert(written["payload"].end_with?("..."))
      assert_equal(50, written["keys"].size)
      refute_includes(records.first.to_json, "secret")
    end
  end

  context "when arguments are a huge hash" do
    let(:arguments) { (1..60_000).to_h { |i| ["key#{i}", i] } }

    before { audit.result(call_id, "x" * 5_000, arguments, outcome: "rejected", sync: true) }

    it "writes the rejection with the hash and the tool name cut" do
      assert_equal(1, records.size)
      assert_equal(50, record["arguments"].size)
      assert_equal(1_027, record["tool"].size)
    end
  end

  context "when arguments stay big after the cuts" do
    let(:arguments) { (1..50).to_h { |i| ["key#{i}", "v" * 2_000] } }

    before { audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: true) }

    it "writes a cut preview of them" do
      assert(record.dig("arguments", "truncated"))
      assert_operator(record.dig("arguments", "size"), :>, 16_384)
      assert_equal(1_024, record.dig("arguments", "preview").bytesize)
      assert_operator(records.first.to_json.bytesize, :<, 4_096)
    end
  end

  context "when actor callable is configured" do
    before do
      Karafka::Web.config.mcp.audit.actor = ->(rack_env) { { user: "admin", ip: rack_env["REMOTE_ADDR"] } }
      audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: true)
    end

    it { assert_equal({ "user" => "admin", "ip" => "10.0.0.1" }, record["actor"]) }
  end

  context "when actor callable returns nil" do
    before do
      Karafka::Web.config.mcp.audit.actor = ->(_rack_env) {}
      audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: true)
    end

    it { assert_equal("10.0.0.1", record.dig("actor", "remote_ip")) }
  end

  context "when the write fails" do
    let(:failing) { stub }
    let(:events) { [] }

    before do
      failing.stubs(:produce_sync).raises(WaterDrop::Errors::ProduceError)
      failing.stubs(:produce_async).raises(WaterDrop::Errors::ProduceError)
      Karafka::Web.producers.stubs(:fully_acked).returns(failing)
      Karafka::Web.producers.stubs(:default).returns(failing)
      Karafka.monitor.stubs(:instrument).with { |name, payload| events << [name, payload] }
    end

    it "returns false and instruments the error" do
      refute(audit.intent(call_id, "karafka_test", arguments))
      refute(audit.result(call_id, "karafka_test", arguments, outcome: "ok", sync: false))
      assert_equal(%w[error.occurred error.occurred], events.map(&:first))
      assert_equal("web.mcp.audit.error", events.first.last[:type])
    end
  end

  describe "#summarize" do
    let(:data) do
      {
        errors: [1, 2, 3],
        total: 7,
        truncated: false,
        topic: "orders",
        note: "a" * 500,
        details: { a: 1 }
      }
    end

    it "keeps counts and short scalars only" do
      assert_equal({ errors: 3, total: 7, truncated: false, topic: "orders" }, audit.summarize(data))
    end

    it { assert_nil(audit.summarize(nil)) }
  end
end
