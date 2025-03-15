public with sharing class JobApplicationController {
   

    @AuraEnabled
    public static Candidature__c createJobApplication(String lastName, String firstName, String email, String phone, String coverLetter, Id jobOfferId) {
      Candidature__c jobApplication = new Candidature__c(
        Name = lastName,
        Pr_nom_du_candidat__c = firstName,
        Email__c = email,
        T_l_phone__c = phone,
        Lettre_de_motivation__c = coverLetter,
        Offre_d_emploi_li_e__c = jobOfferId

      );
      insert jobApplication;
      return jobApplication;
    }
  
    @AuraEnabled
    public static void setLink(Id recordId, String fileURL, String contentDocumentId) {
      ContentDocumentLink cdl = new ContentDocumentLink();
      cdl.LinkedEntityId = recordId;
      cdl.ContentDocumentId = contentDocumentId;
      cdl.ShareType = 'V';
      cdl.Visibility = 'AllUsers';
      insert cdl;
  
      Candidature__c candidate = [SELECT Id FROM Candidature__c WHERE Id = :recordId LIMIT 1];
      candidate.CV__c = fileURL;
      update candidate;
    }
  

  }