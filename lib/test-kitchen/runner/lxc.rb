module TestKitchen
  module Runner
    class LXC < Base

      NATTY = 'ubuntu-11.04'
      LXC_HOST = NATTY

      attr_reader :options
      attr_writer :nested_runner

      def initialize(env, options={})
        super
        raise_unless_host_box_available
        @env, @options = env, options
      end

      def nested_runner
        @nested_runner ||=
          Runner.targets['vagrant'].new(@env, @options).tap do |vagrant|
            vagrant.platform = NATTY
          end
      end

      def provision
        nested_runner.provision
        nested_runner.with_target_vms(LXC_HOST) do |vm|
          nested_runner.execute_remote_command vm,
            "sudo test-kitchen-lxc provision '#{platform}' '#{env.project.name}_test::#{configuration.name}'",
            "Provisioning Linux Container: #{platform} [#{configuration.name}]"
        end
      end

      def run_list
        ['test-kitchen::lxc']
      end

      def status
        puts 'status'
      end

      def destroy
        nested_runner.with_target_vms(LXC_HOST) do |vm|
          nested_runner.execute_remote_command vm,
            "sudo test-kitchen-lxc destroy '#{platform}'",
              'Destroying Linux Container'
        end
        # TODO: Need to collect the nested VM
        #nested_runner.destroy
      end

      def ssh
        # TODO: SSH to the correct host
        nested_runner.ssh
      end

      def execute_remote_command(node, command, message=nil)
        nested_runner.with_target_vms(LXC_HOST) do |vm|
          nested_runner.execute_remote_command(vm, "sudo test-kitchen-lxc run '#{node}' '#{command}'", message)
        end
      end

      private

      def raise_unless_host_box_available
        distro_name, distro_version = NATTY.split('-')
        unless env.platforms[distro_name] and env.platforms[distro_name].versions[distro_version]
          raise ArgumentError, "LXC host box '#{NATTY}' is not available"
        end
      end

    end
  end
end