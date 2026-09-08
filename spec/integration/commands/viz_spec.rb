require "integration_helper"

# Needs the graphviz binary, and the generated image differs on Windows.
RSpec.describe "berks viz", type: :aruba, graphviz: true do
  before { write_berksfile("cookbook 'fake', '1.0.0'") }

  it "renders a graph for a flat dependency set" do
    write_lockfile("DEPENDENCIES\n  fake (= 1.0.0)\n\nGRAPH\n  fake (1.0.0)\n")

    berks! "viz"

    expect(exist?("graph.png")).to be(true)
  end

  it "renders a graph with transitive dependencies" do
    write_lockfile(<<~LOCK)
      DEPENDENCIES
        fake (= 1.0.0)

      GRAPH
        dep (1.0.0)
        fake (1.0.0)
          dep (~> 1.0.0)
    LOCK

    berks! "viz"

    expect(exist?("graph.png")).to be(true)
  end

  it "writes to a custom outfile" do
    write_lockfile(<<~LOCK)
      DEPENDENCIES
        fake (= 1.0.0)

      GRAPH
        dep (1.0.0)
        fake (1.0.0)
          dep (~> 1.0.0)
    LOCK

    berks! "viz --outfile ponies.png"

    expect(exist?("graph.png")).to be(false)
    expect(exist?("ponies.png")).to be(true)
  end

  it "requires a lockfile" do
    berks "viz"

    expect_output("Lockfile not found! Run `berks install` to create the lockfile.")
    expect_exit_status(Berkshelf::LockfileNotFound)
  end
end
