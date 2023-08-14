# frozen_string_literal: true

RSpec.describe_current do
  describe '#install' do
    subject(:run) { described_class.new.install }

    let(:topics_creator) { Karafka::Web::Management::CreateTopics.new }
    let(:states_creator) { Karafka::Web::Management::CreateInitialStates.new }
    let(:boot_file_extender) { Karafka::Web::Management::ExtendBootFile.new }

    before do
      allow(topics_creator.class).to receive(:new).and_return(topics_creator)
      allow(states_creator.class).to receive(:new).and_return(states_creator)
      allow(boot_file_extender.class).to receive(:new).and_return(boot_file_extender)

      allow(topics_creator).to receive(:call)
      allow(states_creator).to receive(:call)
      allow(boot_file_extender).to receive(:call)
    end

    it 'expect to create topics, populate data and expand boot file' do
      run
      expect(topics_creator).to have_received(:call)
      expect(states_creator).to have_received(:call)
      expect(boot_file_extender).to have_received(:call)
    end
  end

  describe '#migrate' do
    subject(:run) { described_class.new.migrate }

    let(:topics_creator) { Karafka::Web::Management::CreateTopics.new }
    let(:states_creator) { Karafka::Web::Management::CreateInitialStates.new }

    before do
      allow(topics_creator.class).to receive(:new).and_return(topics_creator)
      allow(states_creator.class).to receive(:new).and_return(states_creator)

      allow(topics_creator).to receive(:call)
      allow(states_creator).to receive(:call)
    end

    it 'expect to create topics and their states' do
      run
      expect(topics_creator).to have_received(:call)
      expect(states_creator).to have_received(:call)
    end
  end

  describe '#reset' do
    subject(:run) { described_class.new.reset }

    let(:topics_reseter) { Karafka::Web::Management::DeleteTopics.new }
    let(:topics_creator) { Karafka::Web::Management::CreateTopics.new }
    let(:states_creator) { Karafka::Web::Management::CreateInitialStates.new }

    before do
      allow(topics_reseter.class).to receive(:new).and_return(topics_reseter)
      allow(topics_creator.class).to receive(:new).and_return(topics_creator)
      allow(states_creator.class).to receive(:new).and_return(states_creator)

      allow(topics_reseter).to receive(:call)
      allow(topics_creator).to receive(:call)
      allow(states_creator).to receive(:call)
    end

    it 'expect to remote topics, create topics and their states' do
      run
      expect(topics_reseter).to have_received(:call)
      expect(topics_creator).to have_received(:call)
      expect(states_creator).to have_received(:call)
    end
  end

  describe '#uninstall' do
    subject(:run) { described_class.new.uninstall }

    let(:deleter) { Karafka::Web::Management::DeleteTopics.new }
    let(:cleaner) { Karafka::Web::Management::CleanBootFile.new }

    before do
      allow(deleter.class).to receive(:new).and_return(deleter)
      allow(cleaner.class).to receive(:new).and_return(cleaner)

      allow(deleter).to receive(:call)
      allow(cleaner).to receive(:call)
    end

    it 'expect to delete and clean' do
      run
      expect(deleter).to have_received(:call)
      expect(cleaner).to have_received(:call)
    end
  end

  describe '#enable!' do
    subject(:run) { described_class.new.enable! }

    let(:runner) { Karafka::Web::Management::Enable.new }

    before do
      allow(runner.class).to receive(:new).and_return(runner)
      allow(runner).to receive(:call)
    end

    it 'expect to enable' do
      run
      expect(runner).to have_received(:call)
    end
  end
end
