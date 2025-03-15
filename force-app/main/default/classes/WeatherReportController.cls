public with sharing class WeatherReportController {
    private static final String GEONAMES_USERNAME = 'sawababdlfttah'; 
    
    // Weather Data class
    public class WeatherData {
        @AuraEnabled public Decimal temperature { get; set; }
        @AuraEnabled public Decimal windSpeed { get; set; }
        @AuraEnabled public Decimal humidity { get; set; }
        @AuraEnabled public String clouds { get; set; }
    }

    // City Data class (city details)
    public class CityData {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public Decimal lat { get; set; }
        @AuraEnabled public Decimal lng { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static WeatherData getWeatherByCoordinates(Decimal latitude, Decimal longitude) {
        try {
            String endpoint = 'https://secure.geonames.org/findNearByWeatherJSON' +
                '?lat=' + latitude +
                '&lng=' + longitude +
                '&username=' + GEONAMES_USERNAME;

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            
            HttpResponse response = http.send(request);
            System.debug('API Response Status: ' + response.getStatusCode());
            System.debug('API Response Body: ' + response.getBody());
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                if (responseMap.containsKey('weatherObservation')) {
                    Map<String, Object> weatherObs = (Map<String, Object>)responseMap.get('weatherObservation');
                    WeatherData weather = new WeatherData();
                    
                    // Safely parse values into correct types
                    weather.temperature = tryParseDecimal(weatherObs.get('temperature'));
                    weather.windSpeed = tryParseDecimal(weatherObs.get('windSpeed'));
                    weather.humidity = tryParseDecimal(weatherObs.get('humidity'));
                    weather.clouds = (String)weatherObs.get('clouds');
                    
                    return weather;
                }
            }

            throw new AuraHandledException('Weather data not found.');
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving weather data: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static WeatherData getWeatherByCityName(String cityName) {
        WeatherData weather = new WeatherData();
        
        try {
            // Step 1: Get city coordinates using city name
            String cityEndpoint = 'http://api.geonames.org/searchJSON?q=' + EncodingUtil.urlEncode(cityName, 'UTF-8') + '&maxRows=1&username=' + GEONAMES_USERNAME;
            
            HttpRequest cityRequest = new HttpRequest();
            cityRequest.setEndpoint(cityEndpoint);
            cityRequest.setMethod('GET');
            
            Http http = new Http();
            HttpResponse cityResponse = http.send(cityRequest);
            
            if (cityResponse.getStatusCode() == 200) {
                Map<String, Object> cityResponseMap = (Map<String, Object>)JSON.deserializeUntyped(cityResponse.getBody());
                
                if (cityResponseMap.containsKey('geonames')) {
                    List<Object> geonames = (List<Object>)cityResponseMap.get('geonames');
                    
                    if (!geonames.isEmpty()) {
                        Map<String, Object> city = (Map<String, Object>)geonames[0];
                        
                        // Convert string coordinates to decimal using tryParseDecimal
                        Decimal latitude = tryParseDecimal(city.get('lat'));
                        Decimal longitude = tryParseDecimal(city.get('lng'));
                        
                        if (latitude != null && longitude != null) {
                            // Get weather using coordinates
                            return getWeatherByCoordinates(latitude, longitude);
                        } else {
                            throw new AuraHandledException('Invalid coordinates for the city.');
                        }
                    } else {
                        throw new AuraHandledException('City not found.');
                    }
                }
            }
            throw new AuraHandledException('Error retrieving city data.');
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    // Helper method to safely parse Decimal
    private static Decimal tryParseDecimal(Object value) {
        try {
            if (value != null) {
                // Check if the value is a String and try to convert it
                String valueAsString = String.valueOf(value).trim();
                
                if (String.isNotBlank(valueAsString)) {
                    return Decimal.valueOf(valueAsString);
                } else {
                    return null;  // Return null if value is empty or blank
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing value to Decimal: ' + e.getMessage());
        }
        return null;  // Return null if parsing fails
    }

    private static void sendEmailReport(List<String> toAddresses, String weatherReport, String subject) {
        if (toAddresses.isEmpty()) {
            throw new AuraHandledException('No email recipients found.');
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(weatherReport);
        
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        } catch (Exception e) {
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String sendWeatherReportToAll(Id accountId, WeatherData weatherData) {
        List<String> results = new List<String>();
        
        // Send to active users
        List<String> userEmails = new List<String>();
        for(User u : [SELECT Email FROM User WHERE IsActive = true AND Email != null]) {
            if(!u.Email.containsIgnoreCase('noreply') && 
               !u.Email.containsIgnoreCase('job@') && 
               !u.Email.containsIgnoreCase('jonapplication@')) {
                userEmails.add(u.Email);
            }
        }
        
        // Send to account owner
        Account acc = [SELECT OwnerId, Owner.Email FROM Account WHERE Id = :accountId];
        if(acc.Owner.Email != null) {
            userEmails.add(acc.Owner.Email);
        }
        
        // Send to contacts
        List<Contact> contacts = [
            SELECT Email, Name 
            FROM Contact 
            WHERE AccountId = :accountId 
            AND Email != null
        ];
        
        List<String> contactEmails = new List<String>();
        for(Contact c : contacts) {
            contactEmails.add(c.Email);
        }
        
        // Prepare email content
        String htmlBody = generateWeatherReportHtml(weatherData);
        
        // Send to users and account owner
        if(!userEmails.isEmpty()) {
            sendEmailReport(userEmails, htmlBody, 'Organization Weather Report');
            results.add('Sent to ' + userEmails.size() + ' users');
        }
        
        // Send to contacts
        if(!contactEmails.isEmpty()) {
            sendEmailReport(contactEmails, htmlBody, 'Account Weather Report');
            results.add('Sent to ' + contactEmails.size() + ' contacts');
        }
        
        return String.join(results, ', ');
    }
    
    private static String generateWeatherReportHtml(WeatherData weatherData) {
        return '<h2>Weather Report</h2>' +
               '<p>Temperature: ' + weatherData.temperature + '°C</p>' +
               '<p>Wind Speed: ' + weatherData.windSpeed + ' km/h</p>' +
               '<p>Humidity: ' + weatherData.humidity + '%</p>' +
               '<p>Conditions: ' + weatherData.clouds + '</p>' +
               '<p>Generated: ' + System.now().format() + '</p>';
    }
}