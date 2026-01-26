# frozen_string_literal: true

RSpec.describe Karafka::Web::Tracking::Consumers::Sampler::Enrichers::ConsumerGroups do
  subject(:enricher) { described_class.new(consumer_groups, subscription_groups) }

  let(:consumer_groups) { {} }
  let(:subscription_groups) { {} }

  describe "#call" do
    context "when consumer groups are empty" do
      it "returns empty hash" do
        expect(enricher.call).to eq({})
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
            topics: {}
          }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(current_time)
      end

      it "calculates poll_age correctly" do
        result = enricher.call
        expect(result["cg1"][:subscription_groups]["sg1"][:state][:poll_age]).to eq(50.0)
      end

      it "rounds poll_age to 2 decimal places" do
        allow(enricher).to receive(:monotonic_now).and_return(polled_at + 1.2345)
        result = enricher.call
        expect(result["cg1"][:subscription_groups]["sg1"][:state][:poll_age]).to eq(1.23)
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
        expect(partition[:transactional]).to be(false)
        expect(partition[:lag_stored]).to eq(10)
        expect(partition[:stored_offset]).to eq(100)
      end

      it "sets transactional to false by default" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        expect(partition[:transactional]).to be(false)
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
        expect(partition[:transactional]).to be(true)
      end

      it "calculates stored_offset as seek_offset - 1" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        expect(partition[:stored_offset]).to eq(149)
      end

      it "calculates lag as ls_offset - seek_offset" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        # lag = 200 - 150 = 50
        expect(partition[:lag]).to eq(50)
      end

      it "sets lag_stored equal to lag" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        expect(partition[:lag_stored]).to eq(50)
      end

      it "sets lag_d to 0" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        expect(partition[:lag_d]).to eq(0)
      end

      it "sets lag_stored_d to 0" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        expect(partition[:lag_stored_d]).to eq(0)
      end

      it "sets committed_offset equal to stored_offset" do
        result = enricher.call
        partition = result["cg1"][:subscription_groups]["sg1"][:topics]["topic1"][:partitions][0]
        expect(partition[:committed_offset]).to eq(149)
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
          expect(partition[:lag]).to eq(0)
          expect(partition[:lag_stored]).to eq(0)
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
        expect(partition[:transactional]).to be(false)
        expect(partition[:lag_stored]).to eq(0)
        expect(partition[:stored_offset]).to eq(0)
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

        expect(partition[:transactional]).to be(false)
        expect(partition[:lag_stored]).to eq(0)
        expect(partition[:stored_offset]).to eq(0)
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

        expect(partition[:transactional]).to be(false)
        expect(partition[:lag_stored]).to eq(0)
        expect(partition[:stored_offset]).to eq(0)
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
          "sg1" => { polled_at: 100.0, topics: {} },
          "sg2" => { polled_at: 200.0, topics: {} }
        }
      end

      before do
        allow(enricher).to receive(:monotonic_now).and_return(250.0)
      end

      it "enriches all consumer groups" do
        result = enricher.call

        expect(result["cg1"][:subscription_groups]["sg1"][:state][:poll_age]).to eq(150.0)
        expect(result["cg2"][:subscription_groups]["sg2"][:state][:poll_age]).to eq(50.0)
      end
    end
  end
end
