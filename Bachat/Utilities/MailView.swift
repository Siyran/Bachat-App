import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var resultError: Error?
    
    var toRecipients: [String]
    var subject: String
    var messageBody: String
    
    var attachmentData: Data? = nil
    var attachmentMimeType: String? = nil
    var attachmentFileName: String? = nil
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var resultError: Error?
        
        init(isShowing: Binding<Bool>,
             resultError: Binding<Error?>) {
            _isShowing = isShowing
            _resultError = resultError
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                isShowing = false
            }
            if let error = error {
                self.resultError = error
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing,
                           resultError: $resultError)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(toRecipients)
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
        
        if let data = attachmentData, let mime = attachmentMimeType, let name = attachmentFileName {
            vc.addAttachmentData(data, mimeType: mime, fileName: name)
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {
        // Nothing to update
    }
}
