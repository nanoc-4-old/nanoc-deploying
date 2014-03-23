# encoding: utf-8

usage       'deploy [options]'
summary     'deploy the compiled site'
description "
Deploys the compiled site. The compiled site contents in the output directory will be uploaded to the destination, which is specified using the `--target` option.
"

option :t, :target,           'specify the location to deploy to (default: `default`)', :argument => :required
flag   :C, :'no-check',       'do not run the issue checks marked for deployment'
flag   :L, :list,             'list available locations to deploy to'
flag   :D, :'list-deployers', 'list available deployers'
option :n, :'dry-run',        'show what would be deployed'

module Nanoc::Deploying

  class Command < ::Nanoc::CLI::CommandRunner

    def run
      load_site

      # List deployers
      if options[:'list-deployers']
        puts 'Available deployers:'
        Nanoc::Deploying::Deployer.all_identifiers.each do |name|
          puts "  #{name}"
        end
        return
      end

      # Get & list configs
      deploy_configs = site.config.fetch(:deploy, {})

      if options[:list]
        if deploy_configs.empty?
          puts  'No deployment configurations.'
        else
          puts 'Available deployment configurations:'
          deploy_configs.keys.each do |name|
            puts "  #{name}"
          end
        end
        return
      end

      # Can't proceed further without a deploy config
      if deploy_configs.empty?
        raise Nanoc::Errors::GenericTrivial, 'The site has no deployment configurations.'
      end

      # Get target
      target = options.fetch(:target, :default).to_sym
      config = deploy_configs.fetch(target) do
        raise Nanoc::Errors::GenericTrivial, "The site has no deployment configuration for #{target}."
      end

      # Get deployer
      name = config.fetch(:kind) do
        $stderr.puts 'Warning: The specified deploy target does not have a kind attribute. Assuming rsync.'
        'rsync'
      end
      deployer_class = Nanoc::Deploying::Deployer.named(name.to_sym)
      if deployer_class.nil?
        names = Nanoc::Deploying::Deployer.all_identifiers.join(', ')
        raise Nanoc::Errors::GenericTrivial, "The specified deploy target has an unrecognised kind “#{name}” (expected one of #{names})."
      end

      # Check
      unless options[:'no-check']
        runner = Nanoc::Checking::Runner.new(site)
        if runner.has_dsl?
          puts 'Running issue checks…'
          ok = runner.run_for_deploy
          if !ok
            puts 'Issues found, deploy aborted.'
            return
          end
          puts 'No issues found. Deploying!'
        end
      end

      # Run
      deployer = deployer_class.new(
        site.config[:build_dir],
        config,
        :dry_run => options[:'dry-run'])
      deployer.run
    end

  end

end

runner Nanoc::Deploying::Command
