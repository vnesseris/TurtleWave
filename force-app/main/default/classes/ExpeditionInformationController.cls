public with sharing class ExpeditionInformationController {

    class ExpeditionWrapper{
      @AuraEnabled public String expeditionName;
      @AuraEnabled public String expeditionId;
      @AuraEnabled public String expeditionStatus;
      @AuraEnabled public String expeditionDuration;
      @AuraEnabled public List<Expedition_Action__c> expeditionActions;
      
    }
   
    @AuraEnabled(cacheable=true)
    public static ExpeditionWrapper getUserActiveExpedition(Id uId){
        try {
            Expedition_Member__c activeExpedition = [SELECT Id, Name, Expedition__c, 
                Expedition__r.Name, Expedition__r.Status__c, 
                Expedition__r.Expedition_Start_Date__c, Expedition__r.Expedition_End_Date__c 
                FROM Expedition_Member__c 
                WHERE Contact__r.User__c = :uId
                AND Expedition__r.Expedition_End_Date__c >= TODAY 
                AND Expedition__r.Expedition_Start_Date__c <= TODAY ];
            
            List<Expedition_Action__c> actions = [SELECT Id, Title__c, Action_Completed__c, Description__c, Findings_Input__c 
                FROM Expedition_Action__c 
                WHERE Expedition__c = :activeExpedition.Expedition__c];

            ExpeditionWrapper expeditionWrapper = new ExpeditionWrapper();
            expeditionWrapper.expeditionName = activeExpedition.Expedition__r.Name;
            expeditionWrapper.expeditionStatus = activeExpedition.Expedition__r.Status__c;
            expeditionWrapper.expeditionDuration = activeExpedition.Expedition__r.Expedition_Start_Date__c.format() + ' - ' + activeExpedition.Expedition__r.Expedition_End_Date__c.format();
            expeditionWrapper.expeditionId = activeExpedition.Expedition__c;
            expeditionWrapper.expeditionActions = actions;

            return expeditionWrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId) {
          ContentVersion cv = createContentVersion(base64, filename);
          ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
          if (cv == null || cdl == null)  return null; 
          return cdl.Id;
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
      ContentVersion cv = new ContentVersion();
      cv.VersionData = EncodingUtil.base64Decode(base64);
      cv.Title = filename;
      cv.PathOnClient = filename;
      try {
        insert cv;
        return cv;
      } catch(Exception e) {
        System.debug(e);
        return null;
      }
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
                if (contentVersionId == null || recordId == null) { return null; }
      ContentDocumentLink cdl = new ContentDocumentLink();
      cdl.ContentDocumentId = [
        SELECT ContentDocumentId 
        FROM ContentVersion 
        WHERE Id =: contentVersionId
      ].ContentDocumentId;
      cdl.LinkedEntityId = recordId;
    
      cdl.ShareType = 'V';
      try {
        insert cdl;
        return cdl;
      } catch(Exception e) {
        System.debug(e);
        return null;
      }
    }

    @AuraEnabled
    public static void completeExpedition(Id recordId){

        try{
            Expedition__c exp = new Expedition__c();
            exp.Id = recordId;
            exp.Status__c = 'Completed';
            update exp;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean validateCompletion(Id expeditionId){
      try {
        List<Expedition_Action__c> expActions = [SELECT Id, Action_Completed__c FROM Expedition_Action__c WHERE Expedition__c =: expeditionId];
        for(Expedition_Action__c act: expActions){
          if(!act.Action_Completed__c) return false;
        }
        return true;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }

    @AuraEnabled
    public static void updateStatusCompleted(Id actionId, Boolean value){
      try {
        Expedition_Action__c expAction = new Expedition_Action__c();
        expAction.Id = actionId;
        expAction.Action_Completed__c = value;
        expAction.Action_Completed_Date__c = Date.TODAY();
        update expAction;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }

    @AuraEnabled
    public static void updateActionFindings(Id actionId, String value){
      try{
        Expedition_Action__c expAction = [SELECT Id, Findings_Input__c FROM Expedition_Action__c 
            WHERE Id =: actionId];
        expAction.Findings_Input__c = String.isBlank(expAction.Findings_Input__c) ? value : expAction.Findings_Input__c + '\n' + value;
        update expAction;
      } catch (Exception e){
        throw new AuraHandledException(e.getMessage());
      }
    }

}