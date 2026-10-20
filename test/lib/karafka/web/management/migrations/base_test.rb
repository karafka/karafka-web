# frozen_string_literal: true

describe_current do
  # Exercised through a real migration instead of an anonymous subclass, because
  # `.sorted_descendants` discovers subclasses via `ObjectSpace` and a throwaway one would leak
  # into the migrator runs of other tests
  let(:migration) { Karafka::Web::Management::Migrations::ConsumersStates::AddJobsCounter }

  it { assert_equal("1.4.0", migration.versions_until) }

  describe "#applicable?" do
    context "when the version is older than the one the migration stops at" do
      it { assert(migration.applicable?("1.3.0")) }
    end

    context "when the version is the one the migration stops at" do
      it { refute(migration.applicable?("1.4.0")) }
    end

    context "when the version is newer only in a multi-digit component" do
      # "1.10.0" sorts before "1.4.0" as a raw string, so this is the case a lexicographic
      # comparison gets wrong
      it { refute(migration.applicable?("1.10.0")) }
    end
  end
end
