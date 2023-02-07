import Intents
import UIKit
import UserNotifications

class CommunicationNotificationPlugin {
    func showNotification(_ notificationInfo: NotificationInfo) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings {
            settings in switch settings.authorizationStatus {
            case .authorized:
                self.dispatchNotification(notificationInfo)
            case .denied:
                return
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .sound]) {
                    didAllow, _ in
                    if didAllow {
                        self.dispatchNotification(notificationInfo)
                    }
                }
            default: return
            }
        }
    }
    
    func dispatchNotification(_ notificationInfo: NotificationInfo) {
        if #available(iOS 15.0, *) {
            let identifier = "mason"
            var content = UNMutableNotificationContent()
            
            content.title = notificationInfo.senderName
            content.subtitle = ""
            content.body = notificationInfo.content
            content.sound = nil
            content.categoryIdentifier = "Event"
            
            var personNameComponents = PersonNameComponents()
            personNameComponents.nickname = notificationInfo.senderName
            
            let avatar = INImage(imageData: notificationInfo.pngImage)
            
            let senderPerson = INPerson(
                personHandle: INPersonHandle(value: notificationInfo.value, type: .unknown),
                nameComponents: personNameComponents,
                displayName: notificationInfo.senderName,
                image: avatar,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: false,
                suggestionType: .none
            )
            
            let mePerson = INPerson(
                personHandle: INPersonHandle(value: "", type: .unknown),
                nameComponents: nil,
                displayName: nil,
                image: nil,
                contactIdentifier: nil,
                customIdentifier: nil,
                isMe: true,
                suggestionType: .none
            )
            
            
            let intent = INSendMessageIntent(
                recipients: [mePerson],
                outgoingMessageType: .outgoingMessageText,
                content: notificationInfo.content,
                speakableGroupName: INSpeakableString(spokenPhrase: notificationInfo.senderName),
                conversationIdentifier: notificationInfo.senderName,
                serviceName: nil,
                sender: senderPerson,
                attachments: nil
            )
            
            intent.setImage(avatar, forParameterNamed: \.sender)
            
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            
            interaction.donate(completion: nil)
            
            do {
                content = try content.updating(from: intent) as! UNMutableNotificationContent
            } catch {
                // Handle errors
            }
            
            // Show 0 seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
            
            // Request from identifier
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // actions
            let close = UNNotificationAction(identifier: "close", title: "Close", options: .destructive)
            //        let reply = UNNotificationAction(identifier: "reply", title: "Reply", options: .foreground)
            let category = UNNotificationCategory(identifier: "Event", actions: [close], intentIdentifiers: [])
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            
            // Add notification request
            UNUserNotificationCenter.current().add(request)
        }
    }
}
