# Woody

**Woody is a static podcast site generator.**

Drop your mp3s in a folder, set some metadata and deploy a full podcast site to Amazon S3.

## Installation

To install, run this:

    $ gem install woody
    
## To Do List/Roadmap
We've got a [Roadmap](https://trello.com/board/woody-to-do-list/50c7903cc0e26dc906001fd6) up and running on Trello where you can suggest features, report bugs and track the project's progress.

## Usage

Install the gem (see above) and create a new project with

    $ woody new projectname

Woody will generate a new project with the name given. Open up the project folder and edit the **woody-config.yml** to your liking.

Dump some mp3s into the **/content** folder and run

    $ woody compile
   
Woody will index the mp3s and prompt you for metadata. You can change this data by editing the **metadata.yml** file in the **/content/** directory.

After this, Woody will generate a full HTML site in the output folder. You can upload this to your host manually or use

    $ woody deploy
   
to deploy your Woody site on to Amazon S3. Be sure to enter your AWS credentials correctly into the configuration file.

**SCREENCAST COMING SOON!**

## About Woody

Woody was developed by David Robertson and David Hewitson as a hosting solution for [an online sitcom](http://spaceferries.com). We decided to release it for free for a laugh.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
