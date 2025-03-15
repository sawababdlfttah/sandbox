public class CandidatureTriggerHandler {
    
    public static void handleBeforeInsert(List<Candidature__c> newCandidatures) {
    }
    
   public static void handleAfterInsert(List<Candidature__c> newCandidatures) {
       sendConfirmationEmails(newCandidatures);
  }
    private static void sendConfirmationEmails(List<Candidature__c> newCandidatures) {
    List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
    
    try {
        EmailTemplate template = [SELECT Id, Name, Subject, HtmlValue, Body 
                                  FROM EmailTemplate 
                                  WHERE Name = 'Candidature_Confirmation' 
                                  LIMIT 1];
        
        if (template == null) {
            System.debug('Error: Email template "Candidature_Confirmation" not found');
            return;
        }

        Set<Id> candidatureIds = new Set<Id>();
        
        for (Candidature__c candidature : newCandidatures) {
            if (candidature.Id != null) {
                candidatureIds.add(candidature.Id);
            }
        }
        
        Map<Id, Candidature__c> candidatureMap = new Map<Id, Candidature__c>([
            SELECT Id, Name, Offre_d_emploi_li_e__r.Name ,Pr_nom_du_candidat__c
            FROM Candidature__c 
            WHERE Id IN :candidatureIds
        ]);
        
        for (Candidature__c candidature : newCandidatures) {
            if (String.isNotBlank(candidature.Email__c)) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                email.setTemplateId(template.Id);
                email.setTargetObjectId(UserInfo.getUserId()); 
                
                email.setToAddresses(new String[] { candidature.Email__c });

                Candidature__c fullCandidature = candidatureMap.get(candidature.Id);
                String candidateName = fullCandidature != null ? fullCandidature.Name : 'Candidat Inconnu';
                String prNomDuCandidat = fullCandidature != null ? fullCandidature.Pr_nom_du_candidat__c : 'Nom Inconnu';

                String jobTitle = fullCandidature != null && fullCandidature.Offre_d_emploi_li_e__r != null 
                                  ? fullCandidature.Offre_d_emploi_li_e__r.Name 
                                  : 'Poste Inconnu';

                String body = template.HtmlValue.replace('{!Candidature__c.Name}', candidateName)
                                                 .replace('{!Candidature__c.Pr_nom_du_candidat__c}', prNomDuCandidat)
                                                 .replace('{!relatedTo.Offre_d_emploi_li_e__r.Name}', jobTitle);
                email.setHtmlBody(body);
                
                email.setSaveAsActivity(false);
                emailsToSend.add(email);
            }
        }
        
        if (!emailsToSend.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailsToSend, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Messaging.SendEmailError err : results[i].getErrors()) {
                        System.debug('Failed to send email to: ' + emailsToSend[i].getToAddresses()[0] + 
                                     ' Error: ' + err.getMessage());
                    }
                }
            }
        }
        
    } catch (Exception e) {
        System.debug('Error sending emails: ' + e.getMessage() + ' at line ' + e.getLineNumber());
    }
}

}