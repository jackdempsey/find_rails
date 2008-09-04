require 'find'

# Take a directory, and a list of patterns to match, and a list of
# filenames to avoid
def recursive_search(dir,patterns, excludes=[/\.git/, /\.svn/, /,v$/, /\.cvs$/, /\.tmp$/, /^RCS$/, /^SCCS$/])
results = Hash.new{|h,k| h[k] = ''}

Find.find(dir) do |path|
  fb =  File.basename(path) 
  next if excludes.any?{|e| fb =~ e}
  if File.directory?(path)
    if fb =~ /\.{1,2}/ 
      Find.prune
    else
      next
    end
  else  # file...
    File.open(path, 'r') do |f|
      ln = 1
      while (line = f.gets)
        patterns.each do |p|
          if line.include?(p)
            results[p] += "#{path}:#{ln}:#{line}"
          end
        end
        ln += 1
      end
    end
  end
end
return results
end

class Rails2Merb < Thor

  desc 'conversion APP_DIR', "Checks your code and prints out which methods will need to change"
  def conversion(app_dir)
    conversions = {
      'before_filter'   => 'Use before',
      'after_filter'   => 'Use after',
      'render :partial' => 'Use partial',
      'redirect_to' => 'Use redirect',
      'url_for' => 'Use url'
    }

    results = recursive_search("#{File.expand_path('app', app_dir)}",conversions.keys)

    conversions.each do |key, warning|
      puts '--> ' + key
      unless results[key] =~ /^$/
        puts "  !! " + warning + " !!"
        puts '  ' + '.' * (warning.length + 6)
        puts results[key]
      else
        puts "  Clean! Cheers for you!"
      end
      puts
    end
  end
end
