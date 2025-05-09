public with sharing class VinController {
    @AuraEnabled
   public static List<ObjectManagement.validationObject> getCarInformation(String url,String vinNumber,String oppId) {
        Http h= new Http();
        HttpRequest req= new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res= h.send(req);
        System.debug('response:--> ' + res.getBody());
        Map < String,
		Object > resultsMap = ( Map < String,
		Object >) JSON.deserializeUntyped(res.getBody());
		system.debug('resultsMap-->' + resultsMap);
        List <Object > objectResult= ( List <Object> ) resultsMap.get('Results');
        System.debug('nuevo mapa '+ objectResult);


        List<ObjectManagement.validationObject> vinObjectList = ObjectManagement.createResultObject(objectResult);
       ObjectManagement.doFunctions(vinObjectList, vinNumber, oppId);
        
       
        System.debug('-------- resultado con nuevo objecto: '+vinObjectList);
        
       
		return vinObjectList;
    }

    
    @AuraEnabled
    public static Opportunity getOpportunity(String recordId){
        Opportunity opp=[SELECT Id,VIN_Number__c,Year__c from Opportunity where Id =: recordId limit 1];
        return opp;
    }

    
}