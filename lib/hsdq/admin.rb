module Hsdq
  module Admin

    def listener_id(listener_id=nil)
      @listener_id = listener_id if listener_id
      @listener_id
    end

    def listener_version(listener_version=nil)
      @listener_version = listener_version if listener_version
      @listener_version
    end

    def admin_channel
      "#{environment}_#{channel}_admin"
    end

    def admin_versionned_channel
      "#{admin_channel}__#{listener_version}"
    end

    def admin_id_channel
      "#{admin_channel}__#{listener_id}"
    end

    def admin_channels
      @admin_channels ||= %w(admin )
    end

    def admin_listener
      begin
        p "starting admin channels #{admin_channel}, #{admin_versionned_channel}"
        cx_admin.subscribe(admin_channel, admin_versionned_channel) do |on|
          on.message do |a_channel, admin_message_j|
            p "received admin message: #{admin_message_j} from admin channel #{admin_channel} "
            process_admin_message(admin_channel, admin_message_j)
          end
        end
      rescue Redis::BaseConnectionError => e
        p e.inspect
        sleep(1)
        retry
      end
    end

    def process_admin_message(_admin_channel, admin_message_j)
      admin_message = JSON.parse(admin_message_j) rescue {'params' => {'task' => ""}}
      task = admin_message['params'] ? admin_message['params']['task'] : ""
      case task
        when 'stop'
          hsdq_stop!
        when 'start'
          hsdq_start!
        when 'exit'
          hsdq_exit!
      end
    end

  end
end
