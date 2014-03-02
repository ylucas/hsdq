module Hsdq
  module Session

    # store in a hash the session layer either a hash or an array of key values (string or json)
    def hsdq_session_set(session_id, *key_values)
      key_values = key_values[0].to_a if 1 == key_values.flatten.size && key_values[0].is_a?(Hash)
      hkey = session_key(session_id)

      cx_session.multi do
        cx_session.hmset hkey,  *key_values.flatten
        cx_session.expire hkey, 259200 #3 days todo set by options
      end
    end

    # return either an array of values in the order of the keys
    # or in the case of no subkeys passed, return a hash of all the data stored
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