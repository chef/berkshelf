require "spec_helper"

module Berkshelf
  describe Shelf do
    # CachedCookbook serves most of these through delegation rather than defined
    # methods, so a verifying double would reject the stubs even though the calls
    # are real.
    def cached_cookbook(name, version, dependencies: {}, path: "/store/#{name}-#{version}")
      cookbook = double("cached-cookbook-#{name}-#{version}",
        cookbook_name: name,
        version: version,
        dependencies: dependencies,
        path: path)
      # Shelf#find sorts the store's results, so the stand-in has to be
      # comparable the way a real CachedCookbook is.
      allow(cookbook).to receive(:<=>) { |other| version <=> other.version }
      cookbook
    end

    let(:store) { double("cookbook-store") }
    let(:options) { {} }

    subject { described_class.new([], options) }

    before { allow(Berkshelf).to receive(:cookbook_store).and_return(store) }

    describe "#find" do
      context "with a version" do
        it "returns the single matching cookbook in an array" do
          cookbook = cached_cookbook("bacon", "1.0.0")
          allow(store).to receive(:cookbook).with("bacon", "1.0.0").and_return(cookbook)
          expect(subject.find("bacon", "1.0.0")).to eq([cookbook])
        end

        # store.cookbook returns nil for a miss, and the nil is compacted away.
        # Without the emptiness check that nil would flow on to the caller and
        # fail somewhere less obvious.
        it "raises CookbookNotFound when that version is not in the store" do
          allow(store).to receive(:cookbook).with("bacon", "9.9.9").and_return(nil)
          expect { subject.find("bacon", "9.9.9") }.to raise_error(CookbookNotFound)
        end
      end

      context "without a version" do
        it "returns every version of the cookbook" do
          cookbooks = [cached_cookbook("bacon", "1.0.0"), cached_cookbook("bacon", "2.0.0")]
          allow(store).to receive(:cookbooks).with("bacon").and_return(cookbooks)
          expect(subject.find("bacon")).to match_array(cookbooks)
        end

        it "raises CookbookNotFound when the store has no such cookbook" do
          allow(store).to receive(:cookbooks).with("ham").and_return([])
          expect { subject.find("ham") }.to raise_error(CookbookNotFound)
        end
      end
    end

    describe "#contingencies" do
      it "selects only the cookbooks that depend on the given one" do
        bacon = cached_cookbook("bacon", "1.0.0")
        dependent = cached_cookbook("breakfast", "1.0.0", dependencies: { "bacon" => ">= 0.0.0" })
        unrelated = cached_cookbook("lunch", "1.0.0", dependencies: { "soup" => ">= 0.0.0" })
        allow(store).to receive(:cookbooks).and_return([dependent, unrelated])

        expect(subject.contingencies(bacon)).to eq([dependent])
      end
    end

    describe "#uninstall_cookbook" do
      let(:cookbook) { cached_cookbook("bacon", "1.0.0", path: "/store/bacon-1.0.0") }

      before { allow(Berkshelf.formatter).to receive(:msg) }

      context "when nothing depends on the cookbook" do
        before { allow(store).to receive(:cookbooks).and_return([]) }

        it "removes the cookbook without prompting" do
          expect(Berkshelf.ui).not_to receive(:ask)
          expect(FileUtils).to receive(:rm_rf).with("/store/bacon-1.0.0")
          subject.uninstall_cookbook(cookbook)
        end
      end

      context "when another cookbook is contingent on it" do
        before do
          dependent = cached_cookbook("breakfast", "1.0.0", dependencies: { "bacon" => ">= 0.0.0" })
          allow(store).to receive(:cookbooks).and_return([dependent])
        end

        it "removes the cookbook when the user confirms" do
          allow(Berkshelf.ui).to receive(:ask).and_return("y")
          expect(FileUtils).to receive(:rm_rf).with("/store/bacon-1.0.0")
          subject.uninstall_cookbook(cookbook)
        end

        it "aborts without removing anything when the user declines" do
          allow(Berkshelf.ui).to receive(:ask).and_return("n")
          expect(FileUtils).not_to receive(:rm_rf)
          expect { subject.uninstall_cookbook(cookbook) }.to raise_error(SystemExit)
        end

        it "treats an empty answer as a refusal" do
          allow(Berkshelf.ui).to receive(:ask).and_return("")
          expect { subject.uninstall_cookbook(cookbook) }.to raise_error(SystemExit)
        end

        # The force argument used to be ignored in favour of options[:force], so
        # the method only ever forced when the CLI flag happened to be set.
        it "skips the prompt when force is passed as an argument" do
          expect(Berkshelf.ui).not_to receive(:ask)
          expect(FileUtils).to receive(:rm_rf).with("/store/bacon-1.0.0")
          subject.uninstall_cookbook(cookbook, true)
        end
      end
    end

    describe "#list" do
      it "reports an empty shelf" do
        allow(store).to receive(:cookbooks).and_return([])
        expect(Berkshelf.formatter).to receive(:msg).with("There are no cookbooks in the Berkshelf shelf")
        subject.list
      end

      it "groups every version under its cookbook name" do
        allow(store).to receive(:cookbooks).and_return([
          cached_cookbook("bacon", "1.0.0"),
          cached_cookbook("bacon", "2.0.0"),
          cached_cookbook("ham", "1.0.0"),
        ])

        expect(Berkshelf.formatter).to receive(:msg).with("Cookbooks in the Berkshelf shelf:")
        expect(Berkshelf.formatter).to receive(:msg).with("  * bacon (1.0.0, 2.0.0)")
        expect(Berkshelf.formatter).to receive(:msg).with("  * ham (1.0.0)")
        subject.list
      end
    end
  end
end
