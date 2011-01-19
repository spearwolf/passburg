#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "highline/import"

module Passburg  # {{{
  extend self

  CIPHER_ALGORITHM = 'AES256'
  PASSWORD_KEYS = %w(pass pw passwd password passphrase)
  HOME_DIR_PATH = ENV["PASSBURG_HOME"] || File.join(ENV["HOME"], '.passburg')

  class Safe  # {{{
    attr_reader :sections

    def initialize(data)
      @sections = new_sections_array
      parse(data)
    end

    def to_s(show_passwords = false)
      "# passburg safe, v1\n\n" + sections.to_s(show_passwords)
    end

    def find_sections(*query_args)
      query_args.flatten!
      found = sections.select do |section|
        section_values = section.keys.select {|key| !PASSWORD_KEYS.include?(key) }.map {|key| section[key] }
        query_args.all? {|arg| section_values.any? {|value| nil != (value =~ /#{arg}/i) }}
      end
      new_sections_array(found)
    end

    def find(*args)
      find_sections(*args).to_s
    end

    def show(*args)
      find_sections(*args).to_s(true)
    end

    # in data: array of lines
    def parse(data)
      current_section = new_section
      data.each do |line|
        current_line = line.chomp.strip
        case current_line
        when /^$/
          # ignore empty lines
        when /^#.*$/
          # ignore lines starting with '#'
        when /^([\w]+)\s*[:=]\s*(.*)$/
          key, value = $1, $2
          current_section[key] = value
        when /^---+$/
          unless current_section.empty?
            @sections << current_section
            current_section = new_section
          end
        end
      end
      @sections << current_section unless current_section.empty?
    end

    private # {{{

    def define_sections_to_s(instance)
      instance.tap do |instance|
        def instance.to_s(show_passwords = false)
          map {|section| section.to_s(show_passwords) }.join("---\n")
        end
      end
    end

    def new_sections_array(ar = [])
      ar.tap {|sections| define_sections_to_s sections }
    end

    def new_section
      {}.tap do |section|
        def section.to_s(show_passwords = false)
          map {|k, v| show_passwords || !PASSWORD_KEYS.include?(k) ? "#{k}: #{v}\n" : nil }.compact.join
        end
      end
    end
    # }}}
  end
  # }}}

  def ask_for_password  # {{{
    hi = HighLine.new($stdin, $stderr)
    hi.ask("Enter your password: " ) {|q| q.echo = "*" }
  end
  # }}}

  def encrypt(data, pass = ask_for_password)  # {{{
    gpg_action data, pass, "--armor --symmetric --cipher-algo #{CIPHER_ALGORITHM}"
  end
  # }}}

  def decrypt(data, pass = ask_for_password)  # {{{
    gpg_action data, pass, "--no-use-agent --decrypt -"
  end
  # }}}

  def mkdir!(home_path = HOME_DIR_PATH)
    FileUtils.mkdir(home_path) unless File.directory?(home_path)
  end

  private # {{{

  def gpg_action(data, pass, gpg_options)
    gpg = IO.popen("gpg --no-verbose --quiet --batch --no-use-agent --passphrase-fd 0 #{gpg_options}", "r+")
    gpg.puts pass
    gpg.puts data
    gpg.close_write
    gpg.readlines.tap do
      gpg.close
      raise "sorry, wrong password!" unless $?.to_i == 0
    end
  end
  # }}}

end
# }}}

if __FILE__ == $0   # {{{

  Passburg.mkdir!

  @pass = Passburg.ask_for_password
  safe = Passburg.encrypt <<DATA, @pass
# {{{

hallo

eins, zwo, 3!

foo : bar  
pass: secret
type = pizza

---

# empty section here

---

new = section
bla = plah!

# }}}
DATA
  decrypted = Passburg.decrypt(safe, @pass)

  puts safe
  pw_safe = Passburg::Safe.new(decrypted)
  puts pw_safe.to_s

  puts ">>>>>>>>>>> izza:"
  puts pw_safe.find("izza")

  puts ">>>>>>>>>>> PIzza, bar:"
  puts pw_safe.show("PIzza", "bar")

  puts ">>>>>>>>>>> izza, foo:"
  puts pw_safe.show("izza", "foo")

  puts ">>>>>>>>>>> xxx, foo:"
  puts pw_safe.find("xxx", "foo")

  puts "------------[blank safe content]-----------"
  empty_safe = Passburg::Safe.new([])
  puts empty_safe.to_s

end
# }}}
