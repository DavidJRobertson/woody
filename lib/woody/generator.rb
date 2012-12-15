class Woody
  # Handles functions related to generating Woody sites and updating them and their data stores
  module Generator
    # Generates a blank skeleton Woody site
    # Do not call Woody::init before this!
    # @param [String] name specifies the relative directory to create the new site in.
    def self.new_site(name)
      puts "Creating new site '#{name}'..."
      if File.directory?(name)
        puts "Error: directory '#{name}' already exists!"
        return false
      end

      cdir_p(name)
      cpy_t("woody-config.yml", "#{name}/woody-config.yml")

      cdir_p("#{name}/templates")
      cpy_t("layout.html", "#{name}/templates/layout.html")
      cpy_t("index.html", "#{name}/templates/index.html")
      cpy_t("post.html", "#{name}/templates/post.html")

      cdir_p("#{name}/templates/assets")
      cpy_t("stylesheet.css", "#{name}/templates/assets/stylesheet.css")

      cdir_p("#{name}/content")
      cpy_t("metadata.yml", "#{name}/content/metadata.yml")
      cpy_t("iTunes.png", "#{name}/content/iTunes.png")
      cdir_p("#{name}/content/posts")

      cdir_p("#{name}/output")
      cdir_p("#{name}/output/assets")
      cdir_p("#{name}/output/assets/mp3")
      cdir_p("#{name}/output/post")

      puts "Done!"
      puts "Now, do `cd #{name}` then edit the config file, woody-config.yml."
    end

    # Replaces the templates in the Woody site with the gem's current default ones
    def update_templates
      puts "Updating templates..."
      cpy_t("layout.html", "templates/layout.html")
      cpy_t("index.html", "templates/index.html")
      cpy_t("post.html", "templates/post.html")
      cpy_t("stylesheet.css", "templates/assets/stylesheet.css")
      puts "Done! Thanks for updating :)"
    end

    private

    # Creates a directory and its parents if necessary, outputting a notice to STDOUT
    # @param [String] dir specifies the directory to create
    def cdir_p(dir)
      puts "Creating directory '#{dir}'"
      FileUtils.mkdir_p(dir)
    end

    # Copies a file from inside the gem's template directory, to a location in the current Woody site., outputting a notice to STDOUT.
    # @param [String] source specificies the source file (inside the gem's internal template directory)
    # @param [String] destination specidies the destination (inside the Woody site's root directory)
    def cpy_t(source, destination)
      puts "Creating file '#{destination}'"
      FileUtils.cp File.join($source_root, source), destination
    end
  end
end