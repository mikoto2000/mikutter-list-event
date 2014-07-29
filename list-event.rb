# -*- coding: utf-8 -*-

Plugin.create(:list_event) do
    defevent :list_update,  priority: :routine_passive, prototype: [UserList, Message]

    # リストのツイート受信毎に list_upate イベントを発行する
    on_appear do |messages|
        messages.each{ |message|
            Plugin[:list].timelines.each{ |slug, list|
                if list.related?(message)
                    Plugin.call(:list_update, list, message)
                end
            }
        }
    end
end
