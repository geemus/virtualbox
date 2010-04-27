require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SnapshotTest < Test::Unit::TestCase
  setup do
    @klass = VirtualBox::Snapshot
    @interface = mock("isnapshot")
  end

  context "class methods" do
    context "populating relationships" do
      setup do
        @caller = mock("caller")
      end

      should "call populate_machine_relationship for VMs" do
        vm = mock("vm")
        vm.stubs(:is_a?).with(VirtualBox::COM::Interface::Machine).returns(true)
        @klass.expects(:populate_machine_relationship).with(@caller, vm).once
        @klass.populate_relationship(@caller, vm)
      end

      should "call populate_children_relationship for an array" do
        @klass.expects(:populate_children_relationship).with(@caller, [1,2,3]).once
        @klass.populate_relationship(@caller, [1,2,3])
      end

      should "call populate_parent_relationship for a snapshot" do
        ss = mock("snapshot")
        ss.stubs(:is_a?).returns(false)
        ss.stubs(:is_a?).with(VirtualBox::COM::Interface::Snapshot).returns(true)
        @klass.expects(:populate_parent_relationship).with(@caller, ss).once
        @klass.populate_relationship(@caller, ss)
      end

      should "call populate_parent_relationship for nil" do
        @klass.expects(:populate_parent_relationship).with(@caller, nil).once
        @klass.populate_relationship(@caller, nil)
      end
    end

    context "populating machine relationship" do
      setup do
        @caller = mock("caller")
        @machine = mock("imachine")
        @snapshot = mock("snapshot")
        @machine.stubs(:current_snapshot).returns(@snapshot)
      end

      should "just initialize with machine" do
        result = mock("result")
        @klass.expects(:new).with(@snapshot).once.returns(result)
        assert_equal result, @klass.populate_machine_relationship(@caller, @machine)
      end

      should "return nil if there is no current snapshot" do
        @machine.expects(:current_snapshot).returns(nil)
        assert_nil @klass.populate_machine_relationship(@caller, @machine)
      end
    end

    context "populating parent relationship" do
      setup do
        @caller = mock("caller")
        @parent = mock("parent")
      end

      should "just initialize with data" do
        result = mock("result")
        @klass.expects(:new).with(@parent).once.returns(result)
        assert_equal result, @klass.populate_parent_relationship(@caller, @parent)
      end

      should "return nil if there is no parent" do
        assert_nil @klass.populate_parent_relationship(@caller, nil)
      end
    end

    context "populating children relationship" do
      setup do
        @instance = mock("instance")

        @klass.stubs(:new).returns(@instance)
      end

      should "return a proxied collection" do
        result = @klass.populate_children_relationship(nil, [])
        assert result.is_a?(VirtualBox::Proxies::Collection)
      end

      should "call new for every machine" do
        snapshots = []
        5.times { |i| snapshots << mock("s#{i}") }

        expected_result = []
        new_seq = sequence("new_seq")
        snapshots.each do |snapshot|
          expected_value = "instance-#{snapshot.inspect}"
          @klass.expects(:new).with(snapshot).in_sequence(new_seq).returns(expected_value)
          expected_result << expected_value
        end

        assert_equal expected_result, @klass.populate_children_relationship(nil, snapshots)
      end
    end
  end

  context "initializing" do
    should "load attributes from the snapshot" do
      @klass.any_instance.expects(:initialize_attributes).with(@interface).once
      @klass.new(@interface)
    end

    should "set the interface as the interface attribute" do
      @klass.any_instance.stubs(:initialize_attributes)
      instance = @klass.new(@interface)
      assert_equal @interface, instance.interface
    end
  end

  context "initializing attributes" do
    setup do
      @interface.stubs(:refresh_state)
      @klass.any_instance.stubs(:load_interface_attributes)
    end

    should "load interface attribtues" do
      @klass.any_instance.expects(:load_interface_attributes).with(@interface).once
      @klass.new(@interface)
    end

    should "not be dirty" do
      @instance = @klass.new(@interface)
      assert !@instance.changed?
    end

    should "be existing record" do
      @instance = @klass.new(@interface)
      assert !@instance.new_record?
    end
  end

  context "with an instance" do
    setup do
      @klass.any_instance.stubs(:initialize_attributes)
      @instance = @klass.new(@interface)
    end
  end
end