package collector

import (
	"log/slog"
	"net"

	"github.com/prometheus/client_golang/prometheus"
)

type networkIPCollector struct {
	interfaceIPStatus *prometheus.Desc
	logger            *slog.Logger
}

func init() {
	registerCollector("network_ip", defaultEnabled, NewNetworkIPCollector)
}

func NewNetworkIPCollector(logger *slog.Logger) (Collector, error) {
	return &networkIPCollector{
		logger: logger,
		interfaceIPStatus: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "network", "interface_ip_status"),
			"Status of IP address assignment on network interfaces (1 = has IP, 0 = no IP)",
			[]string{"interface", "ip"}, nil,
		),
	}, nil
}

func (c *networkIPCollector) Update(ch chan<- prometheus.Metric) error {
	interfaces, err := net.Interfaces()
	if err != nil {
		return err
	}

	for _, iface := range interfaces {
		addrs, err := iface.Addrs()
		if err != nil {
			c.logger.Warn("Failed to get addresses for interface", "interface", iface.Name, "err", err)
			continue
		}

		hasIP := 0
		for _, addr := range addrs {
			if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
				if ipnet.IP.To4() != nil || ipnet.IP.To16() != nil {
					hasIP = 1
					break
				}
			}
		}

		ipAddr := ""
		if hasIP == 1 {
			for _, addr := range addrs {
				if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
					ipAddr = ipnet.IP.String()
					break
				}
			}
		}

		ch <- prometheus.MustNewConstMetric(
			c.interfaceIPStatus,
			prometheus.GaugeValue,
			float64(hasIP),
			iface.Name, ipAddr,
		)

	}
	return nil
}
