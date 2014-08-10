# -*- coding: utf-8 -*-

Plugin.create(:list_event) do
    defevent :list_update,  priority: :routine_passive, prototype: [UserList, Array]

    # config に設定項目を追加
    settings("リストイベント") do
        settings("基本設定") do
            adjustment 'リストイベント発火間隔', :list_event_interval, 60, 3600
        end
    end

    # 一度配信したメッセージのメッセージ ID を記録する Array
    @appeared = []
    def appeared
        return @appeared ||= []
    end

    # 一度配信したメッセージをもう一度配信しないようにするフィルタ
    # Plugin[:core]のロジックとか流用できないかなぁ...。
    filter_list_update do |list, messages|
        # 配信対象メッセージ抽出
        new_messages = []
        for message in messages do
            if not @appeared.include?(message.id) then
                new_messages.push(message)
                @appeared.push(message.id)
            end
        end

        # なにかしらのメッセージがあればイベント発火
        if not new_messages.empty? then
            [list, new_messages]
        end
    end

    on_boot do |service, message|
        UserConfig[:list_event_interval] ||= 180
        fire(service)
    end

    def fire(service)
        # 1 回ごとに「サービスの数 + サービス毎のリストの数」だけ「lists/statuses」を消費するので注意。
        # TODO: リストくらいはキャッシュしとかないか？
        service.lists.next do |lists|
            lists.each do |list|
                service.list_statuses(
                    :id => list[:id], :cache => false).next do |res|
                        messages = []
                        for r in res do
                            message = Message.new_ifnecessary(
                                :id => r[:id],
                                :message => r[:message],
                                :user => r[:user],
                                :receiver => r[:receiver],
                                :replyto => r[:replyto],
                                :source => r[:source],
                                :geo => r[:geo],
                                :exact => r[:exact],
                                :created => r[:created],
                                :modified => r[:modified])
                            messages.push(message)
                        end

                        Plugin.call(:list_update, list, messages)
                    end
            end
        end

        # 次回発火の予約
        Reserver.new(UserConfig[:list_event_interval]){
            fire(service)
        }
    end
end
