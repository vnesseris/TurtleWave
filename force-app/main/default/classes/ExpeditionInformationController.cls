public with sharing class ExpeditionInformationController {
   
    @AuraEnabled(cacheable=true)
    public static ExpeditionWrapper getUserActiveExpedition(Id uId){
        try {
            Expedition_Member__c activeExpedition = [SELECT Id, Name, Expedition__c, Expedition__r.Name, Expedition__r.Status__c FROM Expedition_Member__c WHERE Contact__r.User__c = :uId ];
            
            List<Expedition_Action__c> actions = [SELECT Id, Title__c, Description__c, Findings_Input__c FROM Expedition_Action__c WHERE Expedition__c = :activeExpedition.Expedition__c];

            ExpeditionWrapper expeditionWrapper = new ExpeditionWrapper();
            expeditionWrapper.expeditionName = activeExpedition.Expedition__r.Name;
            expeditionWrapper.expeditionStatus = activeExpedition.Expedition__r.Status__c;
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
        if (cv == null || cdl == null) { return null; }
        return cdl.Id;
  }
  /*
   * @method createContentVersion() [private]
   * @desc Creates a content version from a given file's base64 and name
   * 
   * @param {String} base64 - base64 string that represents the file
   * @param {String} filename - full file name with extension, i.e. 'products.csv'
   * 
   * @return {ContentVersion} - returns the newly created ContentVersion, or null
   *   if there was an error inserting the record
   */
  private static ContentVersion createContentVersion(String base64, String filename) {
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64);
    cv.Title = filename;
    cv.PathOnClient = filename;
    try {
      insert cv;
      return cv;
    } catch(DMLException e) {
      System.debug(e);
      return null;
    }
  }

   /*
   * @method createContentLink() [private]
   * @desc Creates a content link for a given ContentVersion and record
   * 
   * @param {String} contentVersionId - Id of the ContentVersion of the file
   * @param {String} recordId - Id of the record you want to attach this file to
   * 
   * @return {ContentDocumentLink} - returns the newly created ContentDocumentLink, 
   *   or null if there was an error inserting the record
   */
  private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
              if (contentVersionId == null || recordId == null) { return null; }
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = [
      SELECT ContentDocumentId 
      FROM ContentVersion 
      WHERE Id =: contentVersionId
    ].ContentDocumentId;
    cdl.LinkedEntityId = recordId;
    // ShareType is either 'V', 'C', or 'I'
    // V = Viewer, C = Collaborator, I = Inferred
    cdl.ShareType = 'V';
    try {
      insert cdl;
      return cdl;
    } catch(DMLException e) {
      System.debug(e);
      return null;
    }
  }

    class ExpeditionWrapper{
        @AuraEnabled public String expeditionName;
        @AuraEnabled public String expeditionId;
        @AuraEnabled public String expeditionStatus;
        @AuraEnabled public List<Expedition_Action__c> expeditionActions;

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
}