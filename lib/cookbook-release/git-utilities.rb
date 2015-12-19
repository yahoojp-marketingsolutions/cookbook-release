require 'semantic'
require 'semantic/core_ext'
require 'mixlib/shellout'
require 'highline/import'

class GitUtilities

  def initialize(options={})
    @tag_prefix = options['tag_prefix'] || ''
  end

  def reset_command(new_version)
    "git reset --hard HEAD^ && git tag -d #{new_version}"
  end

  def clean_index?
    clean_index = Mixlib::ShellOut.new("git diff --exit-code")
    clean_index.run_command
    clean_staged = Mixlib::ShellOut.new("git diff --exit-code --cached")
    clean_staged.run_command
    !clean_index.error? && !clean_staged.error?
  end

  def clean_index!
    raise "All changes must be committed!" unless clean_index?
  end

  def compute_last_release

    tag = Mixlib::ShellOut.new([
      'git describe',
      "--tags",
      "--match \"#{@tag_prefix}[0-9]\.[0-9]*\.[0-9]*\""
    ].join " ")
    tag.run_command
    tag.stdout.split('-').first
  end

  def compute_changelog(since)
    # TODO use whole commit message instead of title only
    log_cmd = Mixlib::ShellOut.new("git log --pretty='format:%an <%ae>::%s::%h' #{since}..HEAD")
    log_cmd.run_command
    log = log_cmd.stdout
    log.split("\n").map do |entry|
      author, subject, hash = entry.chomp.split("::")
      Commit.new({
        author: author,
        subject: subject,
        hash: hash
      })
    end.reject { |commit| commit[:subject] =~ /^Merge branch (.*) into/i }
  end

  def mono_commit?(changelog)
    changelog.size == 1
  end

  def commit(version, changelog)
    if mono_commit?(changelog) # amend commit
      options = "--amend --no-edit"
    else # add a commit
      message = "Release #{version}"
      options = "-m \"#{message}\""
    end
    cmd = Mixlib::ShellOut.new("git commit -a #{options}")
    cmd.run_command
    cmd.error!
  end

  def tag(version)
    cmd = Mixlib::ShellOut.new("git tag #{@tag_prefix}#{version}")
    cmd.run_command
    cmd.error!
  end

  def choose_remote
    cmd = Mixlib::ShellOut.new("git remote")
    cmd.run_command
    cmd.error!
    remotes = cmd.stdout.split("\n")
    if remotes.size == 1
      remotes.first
    else
      choose(*remotes)
    end
  end

  def push_tag(version)
    remote = choose_remote
    cmd = Mixlib::ShellOut.new("git push #{remote} #{@tag_prefix}#{version}")
    cmd.run_command
    cmd.error!

    if mono_commit?
      commit_before_amend = git_changelog.first[:hash]
      force = "--force-with-lease=master:#{commit_before_amend}"
    else
      force = ""
    end
    cmd = Mixlib::ShellOut.new("git push #{remote} master #{force}")
    cmd.run_command
    cmd.error!
  end
end