require 'byebug'

class Grep
  @@flags = {}

  Line = Struct.new(:file_name, :line_number, :text) do
  end

  def self.grep(pattern, flags, files)
    self.set_flags flags, files
    all_lines(all_files(files)).inject([]) do |acc, line|
      acc << self.format_line(line, files) if self.matched?(line, pattern); acc
    end.uniq.join("\n")
  end

  private_class_method def self.format_line line, files
    case
    when @@flags["file_name"] && @@flags["line_numbers"]
      line.file_name
    when @@flags["multiple_files"] && @@flags["line_numbers"]
      line.file_name + ":" + line.line_number.to_s + ":" + line.text
    when @@flags["file_name"]
      line.file_name
    when @@flags["multiple_files"]
      line.file_name + ":" + line.text
    when @@flags["line_numbers"]
      line.line_number.to_s + ":" + line.text
    else
      line.text
    end
  end

  private_class_method def self.matched? line, pattern
    prepared_line = line.text
    prepared_pattern = pattern
    if @@flags["case_insensitive"]
      prepared_line = prepared_line.downcase
      prepared_pattern = prepared_pattern.downcase
    end
    return !(prepared_line == prepared_pattern) if (@@flags["inverse"] && @@flags["full_match"])
    return (prepared_line == prepared_pattern) if @@flags["full_match"]
    return !prepared_line.include?(prepared_pattern) if @@flags["inverse"]
    prepared_line.include?(prepared_pattern)
  end

  private_class_method def self.set_flags flags, files
    @@flags = {}
    flags.each do |flag|
      case flag
      when '-n'      
        then @@flags["line_numbers"] = true
      when '-i'      
        then @@flags["case_insensitive"] = true
      when '-l'      
        then @@flags["file_name"] = true
      when '-x'      
        then @@flags["full_match"] = true
      when '-v'      
        then @@flags["inverse"] = true
      end
    end
    @@flags["multiple_files"] = true if files.size > 1
  end

  private_class_method def self.all_files files
    files.inject({}) {|acc, file| acc[file] = File.read(file); acc}
  end

  private_class_method def self.all_lines files
    files.keys.inject([]) do |acc, file_name|
      lines = files[file_name].split("\n")
      lines.each do |line|
        acc << Line.new(file_name, lines.index(line) + 1, line)
      end
      acc
    end
  end
end
