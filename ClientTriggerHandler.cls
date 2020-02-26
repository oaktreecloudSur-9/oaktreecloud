/////////////////////////////////////////////////////////////////////////////
//This is a handler class invoked from client trigger for webservice callout
/////////////////////////////////////////////////////////////////////////////

public class ClientTriggerHandler {
    Public static boolean checkRecursive = true;
    public static void callout(Client__c client){
                String requestBody =  UtilityClass.serializeData(client.Id,'Client__c');
                UtilityClass utilityData = new UtilityClass();
                sObject CSInfoVal = utilityData.getCustomSettingList('Score_Integration__c');
                String endPoint = (String)CSInfoVal.get(Schema.Score_Integration__c.APIEndPoint__c);
                String method = 'POST';   
                map<String,String> headerMap  = new map<String,string>(); 
                headerMap.put('Content-Type','application/json');
                UtilityClass.calloutMethod(endPoint,method,requestBody,headerMap,client.Id,'Client__c');   
    }
}