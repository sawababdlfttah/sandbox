public with sharing class FootballDataAPI {
    @AuraEnabled(cacheable=true)
    public static String getMatches(Integer page) {
        try {
            System.debug('Requesting matches for page: ' + page);
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            
            // Get current date in YYYY-MM-DD format
            String today = System.now().format('yyyy-MM-dd');
            
            String endpoint = 'https://api.football-data.org/v4/matches';
           
            
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('X-Auth-Token', '1d7bcc5cd87f451bb75698bf7ded379d');
            req.setTimeout(10000);
            
            System.debug('Request endpoint: ' + endpoint);
            
            HttpResponse res = http.send(req);
            System.debug('Response status code: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else if (res.getStatusCode() == 429) {
                throw new AuraHandledException('Limite d\'API dépassée. Veuillez réessayer plus tard.');
            } else {
                throw new AuraHandledException('Erreur ' + res.getStatusCode() + ': ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error in getMatches: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Erreur lors de la récupération des matchs: ' + e.getMessage());
        }
    }
}