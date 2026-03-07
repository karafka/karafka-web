# frozen_string_literal: true

describe_current do
  let(:topics_creator) { Karafka::Web::Management::Actions::CreateTopics.new }
  let(:states_creator) { Karafka::Web::Management::Actions::CreateInitialStates.new }
  let(:states_migrator) { Karafka::Web::Management::Actions::MigrateStatesData.new }
  let(:boot_file_extender) { Karafka::Web::Management::Actions::ExtendBootFile.new }

  before do
    topics_creator.class.stubs(:new).returns(topics_creator)
    states_creator.class.stubs(:new).returns(states_creator)
    states_migrator.class.stubs(:new).returns(states_migrator)
    boot_file_extender.class.stubs(:new).returns(boot_file_extender)

    topics_creator.stubs(:call)
    states_creator.stubs(:call)
    boot_file_extender.stubs(:call)
    states_migrator.stubs(:call)
  end

  describe "#install" do
    let(:execute) { described_class.new.install }

    it "expect to create topics, populate data, migrate and expand boot file" do
      topics_creator.expects(:call)
      states_creator.expects(:call)
      states_migrator.expects(:call)
      boot_file_extender.expects(:call)
      execute
    end
  end

  describe "#migrate" do
    let(:execute) { described_class.new.migrate }

    it "expect to create topics and their states" do
      topics_creator.expects(:call)
      states_creator.expects(:call)
      states_migrator.expects(:call)
      execute
    end
  end

  describe "#reset" do
    let(:execute) { described_class.new.reset }

    let(:topics_reseter) { Karafka::Web::Management::Actions::DeleteTopics.new }

    before do
      topics_reseter.class.stubs(:new).returns(topics_reseter)
      topics_reseter.stubs(:call)
    end

    it "expect to remote topics, create topics and their states" do
      topics_reseter.expects(:call)
      topics_creator.expects(:call)
      states_creator.expects(:call)
      states_migrator.expects(:call)
      execute
    end
  end

  describe "#uninstall" do
    let(:execute) { described_class.new.uninstall }

    let(:deleter) { Karafka::Web::Management::Actions::DeleteTopics.new }
    let(:cleaner) { Karafka::Web::Management::Actions::CleanBootFile.new }

    before do
      deleter.class.stubs(:new).returns(deleter)
      cleaner.class.stubs(:new).returns(cleaner)

      deleter.stubs(:call)
      cleaner.stubs(:call)
    end

    it "expect to delete and clean" do
      deleter.expects(:call)
      cleaner.expects(:call)
      execute
    end
  end

  describe "#enable!" do
    let(:execute) { described_class.new.enable! }

    let(:runner) { Karafka::Web::Management::Actions::Enable.new }

    before do
      runner.class.stubs(:new).returns(runner)
      runner.stubs(:call)
    end

    it "expect to enable" do
      runner.expects(:call)
      execute
    end
  end
end
