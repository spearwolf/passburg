#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "highline/import"

module Passburg  # {{{
  extend self

  CIPHER_ALGORITHM = 'AES256'
  PASSWORD_KEYS = %w(pass pw passwd password passphrase)

  class Safe  # {{{
    attr_reader :sections

    def initialize(data)
      @sections = []
      parse(data)
    end

    def to_s
      "# passburg safe, v1\n" + sections_to_s(sections, true)
    end

    def find_sections(*args)
      sections.select do |section|
        section_values = section.keys.select {|key| !PASSWORD_KEYS.include?(key) }.map {|key| section[key] }
        args.all? {|arg| section_values.any? {|value| value =~ /#{arg}/i } }
      end
    end

    def find(*args)
      sections_to_s find_sections(*args)
    end

    def show(*args)
      sections_to_s(find_sections(*args), true)
    end

    private # {{{

    def sections_to_s(sections, show_passwords = false)
      sections.map {|section| (["---\n"] + section.map {|k, v|
        show_passwords || !PASSWORD_KEYS.include?(k) ? "#{k}=#{v}\n" : nil
      }).compact.join }.join
    end

    # in data: array of lines
    def parse(data)
      current_section = {}
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
          #puts "key='#{key}', value='#{value}'"
        when /^---+$/
          unless current_section.empty?
            @sections << current_section
            current_section = {}
          end
          #puts "new section identifier"
        #else
          #puts "ignoring line: '#{current_line}'"
        end
      end
      @sections << current_section unless current_section.empty?
    end
    # }}}
  end
  # }}}

  def ask_for_password  # {{{
    ask("Enter your password: " ) {|q| q.echo = "*" }
  end
  # }}}

  def encrypt(data, pass = ask_for_password)  # {{{
    gpg = IO.popen("gpg --no-verbose --quiet --batch --armor --no-use-agent --symmetric --cipher-algo #{CIPHER_ALGORITHM} --passphrase-fd 0", "r+")
    gpg.puts pass
    gpg.puts data
    gpg.close_write
    gpg.readlines.tap do
      gpg.close
    end
  end
  # }}}

  def decrypt(data, pass = ask_for_password)  # {{{
    gpg = IO.popen("gpg --no-verbose --quiet --batch --no-use-agent --passphrase-fd 0 --decrypt -", "r+")
    gpg.puts pass
    gpg.puts data
    gpg.close_write
    gpg.readlines.tap do
      gpg.close
    end
  end
  # }}}
end
# }}}


if __FILE__ == $0

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

end