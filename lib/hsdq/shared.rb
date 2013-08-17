
module Hsdq
  module Shared

    def placeholder
      "This is a placeholder, you must implement this method in your hsdq class"
    end

    def valid_type?(type)
      %w(request ack callback feedback error).include? type
    end

  end
end