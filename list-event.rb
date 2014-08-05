# -*- coding: utf-8 -*-

Plugin.create(:list_event) do
    defevent :list_update,  priority: :routine_passive, prototype: [UserList, Message]
    def user_lists
        @user_lists ||= []
    end

    # 起動時に全てのサービスを舐めてリストを登録していく。
    on_boot do |_|
        Service.instances.each { |service|
            (service.lists).next do |lists|
                lists.each { |list|
                    user_lists.push(list)
                }
            end
        }
    end

    # リストのツイート受信毎に list_upate イベントを発行する
    on_appear do |messages|
        messages.each{ |message|
            for list in user_lists do
                if list.member?(message.user)
                    Plugin.call(:list_update, list, message)
                end
            end
        }
    end
end
