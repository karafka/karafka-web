# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener that auto-tags the process with group.instance.id when static group membership
          # is used. This improves debugging and allows tracking of processes despite different
          # process ids after deployment.
          #
          # Why tags are kept permanently (not removed when subscription groups stop)
          #
          # In multiplexing scenarios, subscription groups can be dynamically started and stopped.
          # We intentionally keep tags even after subscription groups stop for several reasons:
          #
          # 1. **Historical debugging value**: Knowing that a process was at some point associated
          #    with a specific group.instance.id is valuable for post-mortem debugging, especially
          #    after deployments or restarts where process ids change but instance ids persist.
          #
          # 2. **Current state is shown elsewhere**: The Web UI already displays active subscription
          #    groups with their details in dedicated views. Tags serve a different purpose - quick
          #    visual identification at the process level.
          #
          # 3. **Consistency**: This matches the behavior of other permanent tags like `node_ppid`
          #    which also persist for the lifetime of the process.
          #
          # 4. **Simplicity**: Tracking reference counts for instance ids shared across multiple
          #    subscription groups would add complexity without significant benefit.
          #
          # If you need to see only currently active group.instance.ids, refer to the subscription
          # group details in the Web UI which reflect real-time state.
          class GroupInstanceIds < Base
            # Tags the process with group.instance.id when a subscription group starts
            # and static group membership is configured.
            #
            # Each subscription group gets its own tag key to support multiple static group
            # memberships in a single process. The key format is `gid_<subscription_group_id>`
            # and the value shows the actual group.instance.id.
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_connection_listener_before_fetch_loop(event)
              subscription_group = event[:subscription_group]
              group_instance_id = subscription_group.kafka[:'group.instance.id']

              return unless group_instance_id

              # Use subscription group id as part of the key to support multiple static memberships
              # in a single process without overwriting each other
              tag_key = :"gid_#{subscription_group.id}"
              ::Karafka::Process.tags.add(tag_key, "gid:#{group_instance_id}")
            end
          end
        end
      end
    end
  end
end
