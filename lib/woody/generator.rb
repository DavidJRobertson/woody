module Woody
  module Generator
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
      cpy_t("episode.html", "#{name}/templates/episode.html")

      cdir_p("#{name}/templates/assets")
      cpy_t("stylesheet.css", "#{name}/templates/assets/stylesheet.css")

      cdir_p("#{name}/content")
      cpy_t("metadata.yml", "#{name}/content/metadata.yml")
      cpy_t("iTunes.png", "#{name}/content/iTunes.png")

      cdir_p("#{name}/output")
      cdir_p("#{name}/output/assets")
      cdir_p("#{name}/output/assets/mp3")
      cdir_p("#{name}/output/episode")

      puts "Done!"
      puts "Now, do `cd #{name}` then edit the config file, woody-config.yml."
    end

    def self.update_templates
      puts "Updating templates..."
      cpy_t("layout.html", "templates/layout.html")
      cpy_t("index.html", "templates/index.html")
      cpy_t("episode.html", "templates/episode.html")
      cpy_t("stylesheet.css", "templates/assets/stylesheet.css")
      puts "Done! Thanks for updating :)"
    end

    private

    def self.cdir_p(dir)
      puts "Creating directory '#{dir}'"
      FileUtils.mkdir_p(dir)
    end
    def self.cpy_t(source, destination)
      puts "Creating file '#{destination}'"
      FileUtils.cp File.join($source_root, source), destination
    end
  end
end