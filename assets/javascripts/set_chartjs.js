// Utility Functions
function getRandomColor(alpha = 1) {
  const r = Math.floor(Math.random() * 255);
  const g = Math.floor(Math.random() * 255);
  const b = Math.floor(Math.random() * 255);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function generateColors(count) {
  return Array.from({length: count}, () => getRandomColor(0.6));
}

// Generic Chart Creation Function
function createChart(chartId, chartData, type = 'line', options = {}) {
  try {
    // Log input data for debugging
    console.log(`Creating ${type} chart for ${chartId}`, chartData);

    // Ensure the canvas element exists
    const canvasId = chartId.replace('#', '');
    const canvas = document.getElementById(canvasId);
    
    if (!canvas) {
      console.error(`Canvas element not found: ${canvasId}`);
      return null;
    }

    const ctx = canvas.getContext('2d');
    
    // Prepare datasets
    const datasets = chartData.series.map((series, index) => {
      const baseConfig = {
        label: series.name || `Dataset ${index + 1}`,
        data: series.data,
        borderColor: getRandomColor(),
        backgroundColor: getRandomColor(0.6)
      };

      // Adjust configuration based on chart type
      switch(type) {
        case 'line':
          return {
            ...baseConfig,
            tension: 0.1,
            fill: false
          };
        case 'bar':
          return {
            ...baseConfig,
            borderWidth: 1
          };
        case 'pie':
          return {
            data: Object.values(series.data),
            backgroundColor: generateColors(Object.keys(series.data).length)
          };
        default:
          return baseConfig;
      }
    });

    // Prepare labels
    const labels = type === 'pie' 
      ? Object.keys(chartData.series[0].data) 
      : chartData.categories || [];

    // Create chart
    return new Chart(ctx, {
      type: type,
      data: {
        labels: labels,
        datasets: datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: !!chartData.label,
            text: chartData.label
          },
          legend: {
            display: type !== 'pie',
            position: 'top'
          }
        },
        scales: type !== 'pie' ? {
          y: {
            title: {
              display: !!chartData.label_y_axis,
              text: chartData.label_y_axis
            }
          },
          x: chartData.label_x_axis ? {
            title: {
              display: true,
              text: chartData.label_x_axis
            }
          } : {}
        } : {},
        ...options
      }
    });
  } catch (error) {
    console.error(`Error creating chart for ${chartId}:`, error);
    return null;
  }
}

// Document Ready Handler
document.addEventListener('DOMContentLoaded', function() {
  // Check if Chart is available
  if (typeof Chart === 'undefined') {
    console.error('Chart.js is not loaded');
    return;
  }

  // Commits Charts
  try {
    if (typeof chart_commits_per_month !== 'undefined') {
      createChart('#chart_commits_per_month', chart_commits_per_month, 'line');
    }
    if (typeof chart_commits_per_day !== 'undefined') {
      createChart('#chart_commits_per_day', chart_commits_per_day, 'line', {
        plugins: {
          legend: {
            position: 'left',
            labels: {
              boxWidth: 20
            }
          }
        }
      });
    }
    if (typeof chart_commits_per_hour !== 'undefined') {
      createChart('#chart_commits_per_hour', chart_commits_per_hour, 'bar');
    }
    if (typeof chart_commits_per_weekday !== 'undefined') {
      createChart('#chart_commits_per_weekday', chart_commits_per_weekday, 'pie');
    }

    // Author-specific charts
    document.querySelectorAll('[id^="chart_commits_per_author_"]').forEach(chartEl => {
      const chartId = `#${chartEl.id}`;
      const chartData = window[chartEl.id.replace('#', '')];
      
      if (chartData) {
        createChart(chartId, chartData, 'line');
      }
    });

    // Global commits per author chart
    if (typeof chart_commits_per_author !== 'undefined') {
      createChart('#chart_commits_per_author', chart_commits_per_author, 'bar');
    }
  } catch (error) {
    console.error('Error in chart initialization:', error);
  }
});
