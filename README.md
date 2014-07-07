## Migrate module

Migrate data into Ophal from external sources.


### Usage

Go to http//example.com/admin/content/migrate and follow the wizard instructions.


### Configuration

**Generate a SECRET token**


You can use the Ophal command-line interface ([ophal-cli](http://github.com/ophal/cli)) to generate the token:

    $ ophal uuid #shorthand for: ophal uuid-generate
    7f6b09fd-e993-4efa-a0ba-d8457ed8dc43

**Configure Ophal**

Following is an example configuration for your settings.lua:

    --[[
      Migrate module settings.
    ]]
    settings.migrate = {
      example = {
        description = 'Migrate Example.com',
        base_uri = 'http://www.example.com/ophal_export',
        token = '[your SECRET token]',
      },
    }

**Configure Drupal**

Following example shows what to add to your Drupal settings.php:

    $conf['ophal_export_token'] = '[your SECRET token]';


**Code your migration**

Following code shows the implementation of hook migration(), to import a Drupal site:

    --[[
      Implements hook migration().
    ]]
    function migration()
      return {
        example = {
          type = 'drupal',
          library_path = 'modules.migrate.plugins.drupal',
        },
      }
    end

You can customize the existing Drupal migration plugin with the help of hook migrate_before_create():

    --[[
      Implements hook migrate_before_create().

      Extend comments importer.
    ]]
    function migrate_before_create(plugin, entity_type, entity, data)
      if plugin == 'drupal' then
        if entity_type == 'comment' then
          entity.subject = data.subject
          entity.hostname = data.hostname
          entity.format = data.format
          entity.name = data.name
          entity.mail = data.mail
          entity.homepage = data.homepage
        end
      end
    end

### In Progress

Migrate from

- Drupal 6.x


### TODO

Migrate from:

- Drupal 7.x
- Ophal 0.x
