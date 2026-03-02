# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Enrichers::ConsumerGroups do
  let(:enricher) { described_class.new(consumer_groups, subscription_groups) }

  let(:consumer_groups) { {} }
  let(:subscription_groups) { {} }

  describe "#call" do
    context "when consumer groups are empty" do
      it "returns empty hash" do
        assert_equal({}, enricher.call)
      end
    end

    context "when enriching subscription group with poll age" do
      let(:current_time) { 1000.0 }
      let(:polled_at) { 950.0 }

      let(:consumer_groups) do
        {
          "cg1" => {
            id: "cg1",
            subscription_groups: {
              "sg1" => {
                state: {},
                topics: {}
              }
            }
          }
        }
      end

      let(:subscription_groups) do
        {
          "sg1" => {
            polled_at: polled_at,
            poll_interval: 300_000,
            topics: {}
          }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(current_time)
      end

      it "calculates poll_age correctly" do
        result = enricher.call
        assert_equal(50.0, result["cg1"][:subscription_groups]["sg1"][:state][:poll_age])
      end

      it "rounds poll_age to 2 decimal places" do
        allow(enricher).to receive(:monotonic_now).and_return(polled_at + 1.2345)
        result = enricher.call
        assert_equal(1.23, result["cg1"][:subscription_groups]["sg1"][:state][:poll_age])
      end

      it "copies poll_interval from subscription group tracking" do
        result = enricher.call
        assert_equal(300_000, result["cg1"][:subscription_groups]["sg1"][:state][:poll_interval])
      end

      context "when poll_interval is custom configured" do
        let(:subscription_groups) do
          {
            "sg1" => {
              polled_at: polled_at,
              poll_interval: 600_000,
              topics: {}
            }
          }
        end

        it "preserves the custom poll_interval value" do
          result = enricher.call
          assert_equal(600_000, result["cg1"][:subscription_groups]["sg1"][:state][:poll_interval])
        end
      end
    end

    context "when enriching non-transactional partitions" do
      let(:consumer_groups) do
        {
          "cg1" => {
            id: "cg1",
            subscription_groups: {
              "sg1" => {
                state: {},
                topics: {
                  "topic1" => {
                    partitions: {
                      0 => {
                        lag_stored: 10,
                        stored_offset: 100
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end

      let(:subscription_groups) do
        {
          "sg1" => {
            polled_at: 100.0,
            poll_interval: 300_000,
            topics: {
              "topic1" => {
                0 => {
                  seek_offset: 101,
                  transactional: false
                }
              }
            }
          }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(150.0)
      end

      it "does not enrich when lag_stored is positive" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]

        # Should only set transactional to false, not enrich
        assert_equal(false, partition[:transactional])
        assert_equal(10, partition[:lag_stored])
        assert_equal(100, partition[:stored_offset])
      end

      it "sets transactional to false by default" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        assert_equal(false, partition[:transactional])
      end
    end

    context "when enriching transactional partitions" do
      let(:consumer_groups) do
        {
          "cg1" => {
            id: "cg1",
            subscription_groups: {
              "sg1" => {
                state: {},
                topics: {
                  "topic1" => {
                    partitions: {
                      0 => {
                        lag_stored: 0,
                        stored_offset: 0,
                        ls_offset: 200
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end

      let(:subscription_groups) do
        {
          "sg1" => {
            polled_at: 100.0,
            poll_interval: 300_000,
            topics: {
              "topic1" => {
                0 => {
                  seek_offset: 150,
                  transactional: true
                }
              }
            }
          }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(150.0)
      end

      it "enriches with transactional flag" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        assert_equal(true, partition[:transactional])
      end

      it "calculates stored_offset as seek_offset - 1" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        assert_equal(149, partition[:stored_offset])
      end

      it "calculates lag as ls_offset - seek_offset" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        # lag = 200 - 150 = 50
        assert_equal(50, partition[:lag])
      end

      it "sets lag_stored equal to lag" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        assert_equal(50, partition[:lag_stored])
      end

      it "sets lag_d to 0" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        assert_equal(0, partition[:lag_d])
      end

      it "sets lag_stored_d to 0" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        assert_equal(0, partition[:lag_stored_d])
      end

      it "sets committed_offset equal to stored_offset" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        assert_equal(149, partition[:committed_offset])
      end

      context "when lag calculation would be negative" do
        let(:consumer_groups) do
          {
            "cg1" => {
              id: "cg1",
              subscription_groups: {
                "sg1" => {
                  state: {},
                  topics: {
                    "topic1" => {
                      partitions: {
                        0 => {
                          lag_stored: 0,
                          stored_offset: 0,
                          ls_offset: 100
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        end

        let(:subscription_groups) do
          {
            "sg1" => {
              polled_at: 100.0,
              poll_interval: 300_000,
              topics: {
                "topic1" => {
                  0 => {
                    seek_offset: 150,
                    transactional: true
                  }
                }
              }
            }
          }
        end

        it "sets lag to 0 instead of negative" do
          result = enricher.call
          partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
          # Would be 100 - 150 = -50, but should be 0
          assert_equal(0, partition[:lag])
          assert_equal(0, partition[:lag_stored])
        end
      end
    end

    context "when seek_offset is not yet set" do
      let(:consumer_groups) do
        {
          "cg1" => {
            id: "cg1",
            subscription_groups: {
              "sg1" => {
                state: {},
                topics: {
                  "topic1" => {
                    partitions: {
                      0 => {
                        lag_stored: 0,
                        stored_offset: 0
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end

      let(:subscription_groups) do
        {
          "sg1" => {
            polled_at: 100.0,
            poll_interval: 300_000,
            topics: {
              "topic1" => {
                0 => {
                  seek_offset: -1,
                  transactional: true
                }
              }
            }
          }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(150.0)
      end

      it "does not enrich the partition" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]

        # Should only set transactional to false, not enrich
        assert_equal(false, partition[:transactional])
        assert_equal(0, partition[:lag_stored])
        assert_equal(0, partition[:stored_offset])
      end
    end

    context "when topic is not in subscription group tracking" do
      let(:consumer_groups) do
        {
          "cg1" => {
            id: "cg1",
            subscription_groups: {
              "sg1" => {
                state: {},
                topics: {
                  "topic1" => {
                    partitions: {
                      0 => {
                        lag_stored: 0,
                        stored_offset: 0
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end

      let(:subscription_groups) do
        {
          "sg1" => {
            polled_at: 100.0,
            poll_interval: 300_000,
            topics: {}
          }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(150.0)
      end

      it "does not enrich the partition" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]

        assert_equal(false, partition[:transactional])
        assert_equal(0, partition[:lag_stored])
        assert_equal(0, partition[:stored_offset])
      end
    end

    context "when partition is not in subscription group tracking" do
      let(:consumer_groups) do
        {
          "cg1" => {
            id: "cg1",
            subscription_groups: {
              "sg1" => {
                state: {},
                topics: {
                  "topic1" => {
                    partitions: {
                      0 => {
                        lag_stored: 0,
                        stored_offset: 0
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end

      let(:subscription_groups) do
        {
          "sg1" => {
            polled_at: 100.0,
            poll_interval: 300_000,
            topics: {
              "topic1" => {}
            }
          }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(150.0)
      end

      it "does not enrich the partition" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]

        assert_equal(false, partition[:transactional])
        assert_equal(0, partition[:lag_stored])
        assert_equal(0, partition[:stored_offset])
      end
    end

    context "when handling multiple consumer groups and subscription groups" do
      let(:consumer_groups) do
        {
          "cg1" => {
            id: "cg1",
            subscription_groups: {
              "sg1" => {
                state: {},
                topics: {}
              }
            }
          },
          "cg2" => {
            id: "cg2",
            subscription_groups: {
              "sg2" => {
                state: {},
                topics: {}
              }
            }
          }
        }
      end

      let(:subscription_groups) do
        {
          "sg1" => { polled_at: 100.0, poll_interval: 300_000, topics: {} },
          "sg2" => { polled_at: 200.0, poll_interval: 300_000, topics: {} }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(250.0)
      end

      it "enriches all consumer groups" do
        result = enricher.call

        assert_equal(150.0, result["cg1"][:subscription_groups]["sg1"][:state][:poll_age])
        assert_equal(50.0, result["cg2"][:subscription_groups]["sg2"][:state][:poll_age])
      end
    end
  end
end
