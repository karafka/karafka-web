# frozen_string_literal: true

RSpec.describe_current do
  subject(:extractor) do
    helper = described_class

    Class
      .new { include(helper) }
      .new
  end

  describe "#extract_error_info" do
    context "with standard error scenarios" do
      it "extracts basic error information" do
        error = StandardError.new("test message")
        result = extractor.extract_error_info(error)

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result[0]).to eq("StandardError")
        expect(result[1]).to eq("test message")
        expect(result[2]).to be_a(String)
      end

      it "handles nil error message gracefully" do
        error = StandardError.new(nil)
        result = extractor.extract_error_info(error)

        expect(result[0]).to eq("StandardError")
        expect(result[1]).to eq("StandardError")
        expect(result[2]).to be_a(String)
      end

      it "handles empty error message" do
        error = StandardError.new("")
        result = extractor.extract_error_info(error)

        expect(result[0]).to eq("StandardError")
        expect(result[1]).to eq("")
        expect(result[2]).to be_a(String)
      end
    end

    context "with custom error classes" do
      it "extracts custom error class names" do
        custom_error_class = Class.new(StandardError)
        stub_const("TestError", custom_error_class)

        error = TestError.new("custom error message")
        result = extractor.extract_error_info(error)

        expect(result[0]).to eq("TestError")
        expect(result[1]).to eq("custom error message")
      end

      it "handles nested error classes" do
        nested_error_class = Class.new(StandardError)
        stub_const("TestModule::NestedError", nested_error_class)

        error = TestModule::NestedError.new("nested error")
        result = extractor.extract_error_info(error)

        expect(result[0]).to eq("TestModule::NestedError")
        expect(result[1]).to eq("nested error")
      end
    end

    context "with backtrace processing" do
      it "handles error without backtrace" do
        error = StandardError.new("no backtrace")
        allow(error).to receive(:backtrace).and_return(nil)

        result = extractor.extract_error_info(error)
        expect(result[2]).to eq("")
      end

      it "handles error with empty backtrace" do
        error = StandardError.new("empty backtrace")
        error.set_backtrace([])

        result = extractor.extract_error_info(error)
        expect(result[2]).to eq("")
      end

      it "processes backtrace and removes app root paths" do
        error = StandardError.new("with backtrace")
        app_root = Karafka.root.to_s
        backtrace = [
          "#{app_root}/app/models/user.rb:10:in `method1'",
          "/other/path/file.rb:20:in `method2'",
          "#{app_root}/lib/helper.rb:30:in `method3'"
        ]
        error.set_backtrace(backtrace)

        result = extractor.extract_error_info(error)
        processed_backtrace = result[2]

        expect(processed_backtrace).to include("app/models/user.rb:10:in `method1'")
        expect(processed_backtrace).to include("/other/path/file.rb:20:in `method2'")
        expect(processed_backtrace).to include("lib/helper.rb:30:in `method3'")
        expect(processed_backtrace).not_to include(app_root)
      end

      it "processes backtrace and removes gem home paths" do
        error = StandardError.new("with gem paths")

        gem_home = "/test/gem/home"
        allow(ENV).to receive(:key?).with("GEM_HOME").and_return(true)
        allow(ENV).to receive(:[]).with("GEM_HOME").and_return(gem_home)

        backtrace = [
          "#{gem_home}/gems/some_gem/lib/file.rb:10:in `gem_method'",
          "/other/path/file.rb:20:in `method2'"
        ]
        error.set_backtrace(backtrace)

        result = extractor.extract_error_info(error)
        processed_backtrace = result[2]

        expect(processed_backtrace).to include("gems/some_gem/lib/file.rb:10:in `gem_method'")
        expect(processed_backtrace).to include("/other/path/file.rb:20:in `method2'")
        expect(processed_backtrace).not_to include(gem_home)
      end

      it "handles backtrace when GEM_HOME not set" do
        error = StandardError.new("no gem home")

        allow(ENV).to receive(:key?).with("GEM_HOME").and_return(false)

        backtrace = ["/some/path/file.rb:10:in `method'"]
        error.set_backtrace(backtrace)

        result = extractor.extract_error_info(error)
        expect(result[2]).to include("file.rb:10:in `method'")
      end

      it "expect to return backtrace without the gem root path" do
        error = StandardError.new("with gem root")
        error.set_backtrace(caller)
        result = extractor.extract_error_info(error)

        expect(result[2]).not_to include(Karafka.gem_root.to_s)
      end
    end

    context "with complex backtrace scenarios" do
      it "joins backtrace with newlines" do
        error = StandardError.new("multi-line backtrace")
        backtrace = ["line1:10", "line2:20", "line3:30"]
        error.set_backtrace(backtrace)

        result = extractor.extract_error_info(error)
        expect(result[2]).to eq("line1:10\nline2:20\nline3:30")
      end

      it "handles backtrace with special characters" do
        error = StandardError.new("special chars")
        backtrace = [
          "/path/with spaces/file.rb:10:in `method'",
          "/path/with-dashes/file.rb:20:in `other_method'",
          "/path/with.dots/file.rb:30:in `another_method'"
        ]
        error.set_backtrace(backtrace)

        result = extractor.extract_error_info(error)
        backtrace_result = result[2]

        expect(backtrace_result).to include("with spaces")
        expect(backtrace_result).to include("with-dashes")
        expect(backtrace_result).to include("with.dots")
      end
    end
  end

  describe "#extract_error_message" do
    context "with standard message scenarios" do
      it "extracts simple error message" do
        error = StandardError.new("simple message")
        result = extractor.extract_error_message(error)

        expect(result).to eq("simple message")
      end

      it "converts message to string" do
        error = StandardError.new(12_345)
        result = extractor.extract_error_message(error)

        expect(result).to eq("12345")
      end

      it "handles nil message" do
        error = StandardError.new(nil)
        result = extractor.extract_error_message(error)

        expect(result).to eq("StandardError")
      end
    end

    context "with message length limits" do
      it "limits message to 10,000 characters" do
        long_message = "a" * 15_000
        error = StandardError.new(long_message)
        result = extractor.extract_error_message(error)

        expect(result.length).to eq(10_000)
        expect(result).to eq("a" * 10_000)
      end

      it "preserves messages under limit" do
        message = "a" * 5_000
        error = StandardError.new(message)
        result = extractor.extract_error_message(error)

        expect(result.length).to eq(5_000)
        expect(result).to eq(message)
      end

      it "handles exactly 10,000 character messages" do
        message = "b" * 10_000
        error = StandardError.new(message)
        result = extractor.extract_error_message(error)

        expect(result.length).to eq(10_000)
        expect(result).to eq(message)
      end

      it "expect to trim extremely long message to 10k of characters" do
        msg = "error" * 5_000
        error = StandardError.new(msg)
        extracted_message = extractor.extract_error_message(error)

        expect(extracted_message).to eq(msg[0, 10_000])
      end
    end

    context "with encoding scenarios" do
      it "forces UTF-8 encoding" do
        message = "test message".encode("ASCII")
        error = StandardError.new(message)
        result = extractor.extract_error_message(error)

        expect(result.encoding).to eq(Encoding::UTF_8)
        expect(result).to eq("test message")
      end

      it "scrubs invalid UTF-8 characters when scrub! is available" do
        invalid_utf8 = (+"\xff\xfe invalid").force_encoding("UTF-8")
        error = StandardError.new(invalid_utf8)

        result = extractor.extract_error_message(error)
        expect(result).to be_a(String)
        expect(result.encoding).to eq(Encoding::UTF_8)
      end

      it "handles message without scrub! method gracefully" do
        message = "normal message"
        error = StandardError.new(message)

        message_result = error.message.to_s[0, 10_000]
        message_result.force_encoding("utf-8")
        allow(message_result).to receive(:respond_to?).with(:scrub!).and_return(false)

        result = extractor.extract_error_message(error)
        expect(result).to eq("normal message")
      end
    end

    context "with error handling during extraction" do
      it "returns fallback message when extraction fails" do
        error = StandardError.new("original message")

        allow(error).to receive(:message).and_raise(StandardError, "extraction error")

        result = extractor.extract_error_message(error)
        expect(result).to eq("!!! Error message extraction failed !!!")
      end

      it "handles errors during to_s conversion" do
        error = StandardError.new("message")
        message_mock = double
        allow(error).to receive(:message).and_return(message_mock)
        allow(message_mock).to receive(:to_s).and_raise(StandardError)

        result = extractor.extract_error_message(error)
        expect(result).to eq("!!! Error message extraction failed !!!")
      end
    end

    context "with special message types" do
      it "handles multi-line error messages" do
        message = "Line 1\nLine 2\nLine 3"
        error = StandardError.new(message)
        result = extractor.extract_error_message(error)

        expect(result).to eq(message)
        expect(result).to include("\n")
      end

      it "handles messages with special characters" do
        message = "Error: !@#$%^&*()_+-={}[]|\\:;\"'<>,.?/~`"
        error = StandardError.new(message)
        result = extractor.extract_error_message(error)

        expect(result).to eq(message)
      end

      it "handles unicode characters in messages" do
        message = "Error with unicode: 🚨 ⚠️ 💥"
        error = StandardError.new(message)
        result = extractor.extract_error_message(error)

        expect(result).to eq(message)
      end
    end
  end
end
