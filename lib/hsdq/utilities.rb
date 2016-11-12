module Hsdq
  module Utilities

    # utility method to symbolize the keys of a hash
    #
    # @param [Hash, #a_hash] the hash to be converted
    # @return [Hash] with all keys as symbol
    def deep_symbolize(a_hash)
      JSON.parse(JSON[a_hash], symbolize_names: true)
    end

    # utility method (equivalent to Rails underscore)
    # @param [String, #string] the string to be transformed ie: class/constant name
    # @return [String] underscored string all in lowercase
    def snakify(string)
      string.split(/(?=[A-Z])/).map(&:downcase).join('_')
    end

  end
end