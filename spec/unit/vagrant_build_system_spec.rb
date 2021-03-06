require_relative "spec_helper"

describe VagrantBuildSystem do
  before(:each) do
    @recipe = Recipe.new("spec/helper/recipe_good")
    expect(@recipe).to receive(:change_working_dir)
    @system = VagrantBuildSystem.new(@recipe)
    @system.instance_variable_set(
      :@ssh_output, 'INFO ssh: Executing SSH in subprocess: ["vagrant@192.168.121.65", "-p", "22", "-o", "Compression=yes", "-o", "DSAAuthentication=yes", "-o", "LogLevel=FATAL", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-o", "IdentitiesOnly=yes", "-i", "/home/ms/.vagrant.d/insecure_private_key", "-t", "bash -l -c \'/bin/true\'"]'
    )
  end

  describe "#up" do
    it "raises if up failed" do
      expect(Command).to receive(:run).and_raise(
        Cheetah::ExecutionFailed.new(nil, nil, nil, nil)
      )
      expect { @system.up }.to raise_error(Dice::Errors::VagrantUpFailed)
    end

    it "puts headline and up output on normal operation" do
      expect(Logger).to receive(:info)
      expect(Command).to receive(:run).with(
        "vagrant", "up", {:stdout=>:capture}
      ).and_return("foo")
      expect(Command).to receive(:run).with(
        "vagrant", "ssh", "--debug", "-c", "/bin/true", {:stderr=>:capture}
      )
      expect(Logger).to receive(:info).with("VagrantBuildSystem: foo")
      @system.up
    end
  end

  describe "#provision" do
    it "raises and halts if provision failed" do
      expect(Command).to receive(:run).and_raise(
        Cheetah::ExecutionFailed.new(nil, nil, nil, nil)
      )
      expect(@system).to receive(:halt)
      expect { @system.provision }.to raise_error(
        Dice::Errors::VagrantProvisionFailed
      )
    end

    it "puts headline and provision output on normal operation" do
      expect(Logger).to receive(:info)
      expect(Command).to receive(:run).and_return("foo")
      expect(Logger).to receive(:info).with("VagrantBuildSystem: foo")
      @system.provision
    end
  end

  describe "#halt" do
    it "raises if halt failed" do
      expect(Command).to receive(:run).and_raise(
        Cheetah::ExecutionFailed.new(nil, nil, nil, nil)
      )
      expect { @system.halt }.to raise_error(
        Dice::Errors::VagrantHaltFailed
      )    
    end

    it "puts headline and halt output on normal operation, reset_working_dir" do
      expect(Logger).to receive(:info)
      expect(Command).to receive(:run).and_return("foo")
      expect(Logger).to receive(:info).with("VagrantBuildSystem: foo")
      expect(@recipe).to receive(:reset_working_dir)
      @system.halt
    end
  end

  describe "#get_port" do
    it "extracts forwarded port from vagrant up output" do
      expect(@system.get_port).to eq("22")
      @system.instance_variable_set(:@ssh_output, "foo")
      expect { @system.get_port }.to raise_error(Dice::Errors::GetPortFailed)
    end
  end

  describe "#get_ip" do
    it "returns loopback address" do
      expect(@system.get_ip).to eq("192.168.121.65")
    end
  end

  describe "#is_busy?" do
    it "returns false, never busy" do
      expect(@system.is_busy?).to eq(false)
    end
  end
end
