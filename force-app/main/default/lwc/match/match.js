import { LightningElement, wire, track } from 'lwc';
import getMatches from '@salesforce/apex/FootballDataAPI.getMatches';

export default class Match extends LightningElement {
    @track currentPage = 1;
    @track matches = [];
    @track error;
    @track isLoading = false;
    @track hasMoreMatches = true;

    get todayDate() {
        return new Date().toLocaleDateString('fr-FR', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    @wire(getMatches, { page: '$currentPage' })
    wiredMatches({ error, data }) {
        this.isLoading = true;
        
        if (data) {
            try {
                console.log('Raw API response:', data);
                const parsedData = JSON.parse(data);
                console.log('Parsed data:', parsedData);

                if (parsedData.matches && Array.isArray(parsedData.matches)) {
                    // Update hasMoreMatches based on pagination info
                    const totalPages = parsedData.resultSet?.total || 0;
                    this.hasMoreMatches = this.currentPage * 20 < totalPages; // Assuming 20 matches per page

                    this.matches = parsedData.matches.map(match => ({
                        id: match.id,
                        homeTeam: match.homeTeam?.name || 'Équipe inconnue',
                        awayTeam: match.awayTeam?.name || 'Équipe inconnue',
                        competition: match.competition?.name || '',
                        score: this.formatScore(match),
                        status: this.formatStatus(match.status),
                        utcDate: this.formatDate(match.utcDate)
                    }));
                    this.error = undefined;
                } else {
                    this.matches = [];
                    this.error = 'Aucun match trouvé';
                }
            } catch (e) {
                console.error('Error processing data:', e);
                this.error = 'Erreur lors du traitement des données';
                this.matches = [];
            }
        } else if (error) {
            console.error('Wire service error:', error);
            this.error = error.body?.message || 'Une erreur est survenue';
            this.matches = [];
        }
        
        this.isLoading = false;
    }

    formatDate(utcDate) {
        if (!utcDate) return '';
        try {
            return new Date(utcDate).toLocaleTimeString('fr-FR', {
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (e) {
            return '';
        }
    }

    formatStatus(status) {
        const statusMap = {
            SCHEDULED: 'Programmé',
            LIVE: 'En direct',
            IN_PLAY: 'En cours',
            PAUSED: 'Pause',
            FINISHED: 'Terminé',
            POSTPONED: 'Reporté',
            SUSPENDED: 'Suspendu',
            CANCELED: 'Annulé'
        };
        return statusMap[status] || status;
    }

    formatScore(match) {
        if (!match) return 'N/A';
        
        if (match.status === 'FINISHED' || match.status === 'IN_PLAY') {
            const home = match.score?.fullTime?.home;
            const away = match.score?.fullTime?.away;
            if (home !== undefined && away !== undefined) {
                return `${home} - ${away}`;
            }
        }
        return 'vs';
    }

    handleNextPage() {
        if (this.hasMoreMatches) {
            this.currentPage += 1;
        }
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
        }
    }
}