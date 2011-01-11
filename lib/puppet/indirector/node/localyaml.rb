require 'puppet/node'
require 'puppet/indirector/plain'
require 'puppet/util/file_locking'
require 'yaml'

class Puppet::Node::Localyaml < Puppet::Indirector::Plain
    desc "Load node data from a local YAML file containing a hash with values:
    an array of classes, the environment, and a hash of parameters.  This is
    just like external node classification for the stand-alone puppet client."

    include Puppet::Util::FileLocking

    def find(request)
        node = super

        # Load facts from Facter
        node.fact_merge

        # Load node from local YAML
        file = Puppet[:localyamlfile]
        return node unless FileTest.exist?(file)

        yaml = nil
        begin
            readlock(file) { |fh| yaml = fh.read }
        rescue => detail
            raise Puppet::Error, "Could not read YAML data for %s %s: %s" %
                [indirection.name, request.key, detail]
        end
        begin
            local = YAML.load(yaml)
        rescue => detail
            raise Puppet::Error, "Could not parse YAML data for %s %s: %s" %
                [indirection.name, request.key, detail]
        end

        node.classes = local['classes']
        node.environment = local['environment']
        node.parameters = local['parameters']

        node
    end
end
