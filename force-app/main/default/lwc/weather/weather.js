import { LightningElement, api, wire, track } from 'lwc';
import getWeatherByCity from '@salesforce/apex/WeatherReportController.getWeatherByCityName';
import getWeatherByCoordinates from '@salesforce/apex/WeatherReportController.getWeatherByCoordinates';
//import sendWeatherReportToOrgUsers from '@salesforce/apex/WeatherReportController.sendWeatherReportToOrgUsers';
//import sendWeatherReportToContacts from '@salesforce/apex/WeatherReportController.sendWeatherReportToContacts';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendWeatherReportToAll from '@salesforce/apex/WeatherReportController.sendWeatherReportToAll';

export default class WeatherReport extends LightningElement {
    @api recordId; // For Account context
    @api componentLocation = 'standalone'; // 'standalone' or 'account'
    
    @track weatherData;
    @track loading = false;
    @track error;
    
    cityName = '';
    latitude;
    longitude;
    
    // Get current user's location when in standalone mode
    connectedCallback() {
        if (this.componentLocation === 'standalone') {
            this.getCurrentLocation();
        }
    }
    
    // Get Account's location when in account context
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: ['Account.BillingLatitude', 'Account.BillingLongitude', 'Account.BillingCity'] 
    })
    wiredAccount({ error, data }) {
        if (data) {
            this.latitude = parseFloat(data.fields.BillingLatitude.value);
            this.longitude = parseFloat(data.fields.BillingLongitude.value);
            //latitude: this.latitude ? parseFloat(this.latitude) : null, 
            //longitude: this.longitude ? parseFloat(this.longitude) : null 
            if (this.latitude && this.longitude) {
                this.getWeatherByCoords();
            } else if (data.fields.BillingCity.value) {
                this.cityName = data.fields.BillingCity.value;
                this.getWeatherByCity();
            }
        } else if (error) {
            this.error = error;
        }
    }
    
    // Get current location using browser's geolocation
    getCurrentLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.getWeatherByCoords();
                },
                (error) => {
                    this.error = error.message;
                }
            );
        }
    }
    
    // Handle city input change
    handleCityChange(event) {
        this.cityName = event.target.value;
    }
    
    // Handle coordinate inputs
    handleLatChange(event) {
        this.latitude = event.target.value;
    }
    
    handleLongChange(event) {
        this.longitude = event.target.value;
    }
    
    // Get weather by city name
    async getWeatherByCity() {
        if (!this.cityName) return;
        
        this.loading = true;
        this.error = null;
        
        try {
            this.weatherData = await getWeatherByCity({ cityName: this.cityName });
            this.loading = false;
        } catch (error) {
            this.error = error.message;
            this.loading = false;
        }
    }
    
    // Get weather by coordinates
    async getWeatherByCoords() {
        if (!this.latitude || !this.longitude) return;
        
        this.loading = true;
        this.error = null;
        
        try {
            this.weatherData = await getWeatherByCoordinates({ 
                latitude: this.latitude, 
                longitude: this.longitude 
            });
            this.loading = false;
        } catch (error) {
            this.error = error.message;
            this.loading = false;
        }
    }
    
    // Get weather icon based on clouds description
    get weatherIcon() {
        if (!this.weatherData?.clouds) return 'utility:dayview';
        
        const clouds = this.weatherData.clouds.toLowerCase();
        if (clouds.includes('rain')) return 'utility:water';
        if (clouds.includes('snow')) return 'utility:frozen';
        if (clouds.includes('broken clouds')) return 'utility:salesforce1';
        if (clouds.includes('few clouds')) return 'utility:salesforce1';
        if (clouds.includes('clear')) return 'utility:dayview';
        return 'utility:dayview';
    }async handleSendReport() {
        if (!this.weatherData) {
            this.showToast('Error', 'No weather data available', 'error');
            return;
        }
        
        try {
            const result = await sendWeatherReportToAll({
                accountId: this.recordId,
                weatherData: this.weatherData
            });
            this.showToast('Success', result, 'success');
        } catch (error) {
            this.showToast('Error', error.message || 'Failed to send report', 'error');
        }
    } 
    
    // juste pour afficher dans le console .
    generateWeatherReport() {
        const location = this.cityName || `Coordinates (${this.latitude}, ${this.longitude})`;
        const report = `
            <h2>Weather Report for ${location}</h2>
            <p>Temperature: ${this.weatherData.temperature}°C</p>
            <p>Wind Speed: ${this.weatherData.windSpeed} km/h</p>
            <p>Humidity: ${this.weatherData.humidity}%</p>
            <p>Conditions: ${this.weatherData.clouds}</p>
            <p>Report generated on: ${new Date().toLocaleString()}</p>
        `;
        console.log('Generated Weather Report:', report);
        return report;
    }
 

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}