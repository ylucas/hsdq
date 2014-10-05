module Hsdq
  module Session

    # Store in the session layer in the session hash one or an array of key values (string or json)
    # Create the session hash if it do not exist.
    # @param [String] session_id Use session_key to create the namespaced key based on session_id
    # @param [Hash or Array of key/values] key_values
    def hsdq_session_set(session_id, *key_values)
      key_values = key_values[0].to_a if 1 == key_values.flatten.size && key_values[0].is_a?(Hash)
      hkey = session_key(session_id)

      cx_session.multi do
        cx_session.hmset hkey,  *key_values.flatten
        cx_session.expire hkey, 259200 #3 days todo set by options
      end
    end

    # Retrieve the session hash from the session layer and return the data (see below)
    # @param [String] session_id used to build the unique namespaced key to retrieve the session hash
    # @param [Array of String] keys either an array of keys or nil or nothing
    # @return [Array] of values in the order of the keys passed
    # @return [Hash] in the case of no keys passed, return a hash of all the data stored
    def hsdq_session(session_id, *keys)
      if keys.any?
        #get only the provided keys
        cx_session.hmget session_key(session_id), *keys
      else
        # get all keys return a hash
        cx_session.hgetall session_key(session_id)
      end
    end

    # delete all keys from the session
    def hsdq_session_del(session_id, *keys)
      cx_session.hdel session_key(session_id), *keys.flatten
    end

    # delete the whole session hash
    def hsdq_session_destroy(session_id)
      cx_session.del session_key(session_id)
    end

    # reset the expiration time for the session
    def hsdq_session_expire(session_id, in_seconds)
      cx_session.expire session_key(session_id), in_seconds
    end

    # return the expiration time remaining before expiration
    def hsdq_session_expire_in(session_id)
      cx_session.ttl session_key(session_id)
    end

    # check if a key exist in the session hash
    def hsdq_session_key?(session_id, key)
      cx_session.hexists session_key(session_id), key
    end

  end
end