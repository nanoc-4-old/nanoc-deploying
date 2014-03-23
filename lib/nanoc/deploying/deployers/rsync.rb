# encoding: utf-8

module Nanoc::Deploying::Deployers

  # A deployer that deploys a site using rsync.
  #
  # The configuration has should include a `:dst` value, a string containing
  # the destination to where rsync should upload its data. It will likely be
  # in `host:path` format. It should not end with a slash. For example,
  # `"example.com:/var/www/sites/mysite/html"`.
  #
  # @example A deployment configuration with public and staging configurations
  #
  #   deploy:
  #     public:
  #       kind: rsync
  #       dst: "ectype:sites/stoneship/public"
  #     staging:
  #       kind: rsync
  #       dst: "ectype:sites/stoneship-staging/public"
  #       options: [ "-glpPrtvz" ]
  class Rsync < ::Nanoc::Deploying::Deployer

    identifier :rsync

    # Default rsync options
    DEFAULT_OPTIONS = [
      '--group',
      '--links',
      '--perms',
      '--partial',
      '--progress',
      '--recursive',
      '--times',
      '--verbose',
      '--compress',
      '--exclude=".hg"',
      '--exclude=".svn"',
      '--exclude=".git"'
    ]

    # @see Nanoc::Deploying::Deployer#run
    def run
      require 'systemu'

      # Get params
      src = source_path + '/'
      dst = config[:dst]
      options = config[:options] || DEFAULT_OPTIONS

      # Validate
      raise 'No dst found in deployment configuration' if dst.nil?
      raise 'dst requires no trailing slash' if dst[-1, 1] == '/'

      # Run
      if dry_run
        warn 'Performing a dry-run; no actions will actually be performed'
        run_shell_cmd([ 'echo', 'rsync', options, src, dst ].flatten)
      else
        run_shell_cmd([ 'rsync', options, src, dst ].flatten)
      end
    end

  private

    # Runs the given shell command. It will raise an error if execution fails
    # (results in a nonzero exit code).
    def run_shell_cmd(args)
      status = systemu(args, 'stdout' => $stdout, 'stderr' => $stderr)
      raise "command exited with a nonzero status code #{$CHILD_STATUS.exitstatus} (command: #{args.join(' ')})" if !status.success?
    end

  end

end
