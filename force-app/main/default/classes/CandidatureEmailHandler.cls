public class CandidatureEmailHandler {
    
    public static void sendConfirmationEmails(List<Candidature__c> newCandidatures) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        try {
            // Get the template ID (replace with your template's exact name)
            Id templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'Candidature_Confirmation'].Id;
            
            for (Candidature__c candidature : newCandidatures) {
                if (String.isNotBlank(candidature.Email__c)) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    
                    // Set the recipient email
                    email.setToAddresses(new String[] { candidature.Email__c });
                    
                    // Use the template without setting TargetObjectId
                    email.setTemplateId(templateId);
                    
                    // Link email activity to Candidature__c record
                    email.setWhatId(candidature.Id);
                    
                    emailsToSend.add(email);
                }
            }
            
            // Send all emails
            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }
            
        } catch (Exception e) {
            System.debug('Error sending emails: ' + e.getMessage());
        }
    }
}