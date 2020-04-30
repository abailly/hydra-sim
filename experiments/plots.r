## This file produces the plots for the hydra paper.
library(ggplot2)
library(dplyr)
library(forcats)

theme_set(theme_light())


readData <- function(fp) {
  renameNodes <- function(d) {
    local <- d %>% filter(regions == 'Local') %>%
      mutate(node = fct_recode(
               node, 'Frankfurt' = 'NodeId 0',
               'Frankfurt' = 'NodeId 1',
               'Frankfurt' = 'NodeId 2',
               'Frankfurt' = 'FrankfurtAWS'))
    continental <- d %>% filter(regions == 'Continental') %>%
      mutate(node = fct_recode(
               node,
               'Frankfurt/Ireland' = 'FrankfurtAWS',
               'Frankfurt/Ireland' = 'IrelandAWS',
               'London' = 'LondonAWS',
               'Frankfurt/Ireland' = 'NodeId 0',
               'Frankfurt/Ireland' = 'NodeId 1',
               'London' = 'NodeId 2'))
    global <- d %>% filter(regions == 'Global') %>%
      mutate(node = fct_recode(
               node,
               'Oregon' = 'NodeId 0',
               'Frankfurt/Tokyo' = 'NodeId 1',
               'Frankfurt/Tokyo' = 'NodeId 2',
               'Oregon' = 'OregonAWS',
               'Frankfurt/Tokyo' = 'FrankfurtAWS',
               'Frankfurt/Tokyo' = 'TokyoAWS'))
    bind_rows(local, continental, global)
  }
  d <- read.csv(fp) %>%
    mutate(regions = fct_recode(
             regions,
             'Local' = 'FrankfurtAWS-FrankfurtAWS-FrankfurtAWS',
             'Continental' = 'IrelandAWS-FrankfurtAWS-LondonAWS',
             'Global' = 'OregonAWS-FrankfurtAWS-TokyoAWS'),
           concLabel = fct_recode(
             as.factor(conc),
             'Concurrency 1' = '1',
             'Concurrency 2' = '2',
             'Concurrency 10' = '10',
             'Concurrency 20' = '20'))
  renameNodes(d)
}

breaks <- 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))
baseline_hu_inf <- function(d) {
  geom_line(data = subset(d, object=='hydra-unlimited-infinte-conc-tps'),
            aes(colour = 'Hydra Unlimited', linetype=snapsize))
}
baseline_hu <- function(d) {
  geom_line(data = subset(d, object=='hydra-unlimited-tps'),
            aes(colour = 'Hydra Unlimited', linetype=snapsize))
}

baseline_ft_inf <- function(d) {
  geom_line(data = subset(d, object=='full-trust-infinte-conc-tps'),
            aes(colour = 'Universal'))
}
baseline_ft <- function(d) {
  geom_line(data = subset(d, object=='full-trust-tps'),
            aes(colour = 'Universal'))
}
points <- function(d) {
  geom_point(data = subset(d, object=='tps'))
}

linescale <- scale_linetype_manual('Snapshot size', limits = c('1', '2', '5', '10', 'infinite'), values = c('dotted', 'dashed', 'dotdash', 'longdash', 'solid'))

themeSettings <- theme(legend.position = 'bottom',
                       legend.box = 'vertical',
                       text = element_text(size=24))

tpsPlot <- function(d) {
  ggplot(d, aes(x = bandwidth/1024, y = value)) +
    scale_x_log10(name = 'bandwidth [Mbit/s]'
                , breaks = breaks, minor_breaks = minor_breaks) +
    scale_y_log10(name = 'transaction throughput [tx/s]'
                , breaks = breaks, minor_breaks = minor_breaks) +
    scale_color_hue('Baseline')
}



dSimple = readData('csv/simple.csv')
dPlutus = readData('csv/plutus.csv')


## Comparison of the baselines, without latency
tpsPlot(dSimple) +
  baseline_ft_inf(dSimple) +
  baseline_hu_inf(dSimple) +
  linescale + themeSettings +
  ggtitle('Universal and Hydra Unlimited Baselines',
          subtitle = 'Simple Transactions, Zero Latency')
ggsave('pdf/baselines-nolat-simple.pdf')

tpsPlot(dPlutus) +
  baseline_ft_inf(dPlutus) +
  baseline_hu_inf(dPlutus) +
  linescale + themeSettings +
  ggtitle('Universal and Hydra Unlimited Baselines',
          subtitle = 'Plutus Transactions, Zero Latency')
ggsave('pdf/baselines-nolat-plutus.pdf')

## Comparison of the baselines, including finite latency
tpsPlot(dSimple) +
  baseline_ft(dSimple) + baseline_hu(dSimple) +
  linescale + themeSettings +
  facet_grid(regions ~ concLabel) +
  ggtitle('Universal and Hydra Unlimited Baselines',
          subtitle = 'Simple Transactions')
ggsave('pdf/baselines-simple.pdf')

tpsPlot(dPlutus) +
  baseline_ft(dPlutus) + baseline_hu(dPlutus) +
  linescale + themeSettings +
  facet_grid(regions ~ concLabel) +
  ggtitle('Universal and Hydra Unlimited Baselines',
          subtitle = 'Plutus Transactions')
ggsave('pdf/baselines-plutus.pdf')

## Experimental Evaluation
tpsPlot(dSimple) +
  baseline_ft(dSimple) + baseline_hu(dSimple) +
  points(dSimple) +
  linescale + themeSettings +
  facet_grid(regions ~ concLabel) +
  ggtitle('Experimental Evaluation',
          subtitle = 'Simple Transactions')
ggsave('pdf/tps-simple.pdf')

tpsPlot(dPlutus) +
  baseline_ft(dPlutus) + baseline_hu(dPlutus) +
  points(dPlutus) +
  linescale + themeSettings +
  facet_grid(regions ~ concLabel) +
  ggtitle('Experimental Evaluation',
          subtitle = 'Plutus Transactions')
ggsave('pdf/tps-plutus.pdf')


dSimple2 <- renameNodes(dSimple)


conftimePlot <- function(d) {
ggplot(d, aes(x = bandwidth/1024, y = value)) +
  geom_point(data = subset(d, object == 'conftime-tx'), aes(colour = node), alpha = 0.1) +
  geom_line(data = subset(d, object == 'min-conftime'), aes(colour = node)) +
  scale_x_log10(name = 'bandwidth [Mbits/s]'
              , breaks = breaks, minor_breaks = minor_breaks) +
  scale_y_log10(name = 'transaction confirmation time [s]',
                breaks = 10^(-2:1), minor_breaks = rep(1:9, 4)*(10^rep(-2:1, each=9))) +
  themeSettings +
  scale_colour_hue('Node Location') +
  guides(color = guide_legend(override.aes = list(linetype = 1, alpha = 1))) +
  ggtitle('Transaction Confirmation Time')
}

conftimePlot(dSimple %>% filter(regions == 'Local')) +
  ggtitle(waiver(), subtitle = 'Simple Transactions, Local Cluster') +
  facet_wrap(~ concLabel)
ggsave('pdf/conftime-local-simple.pdf')

conftimePlot(dSimple %>% filter(regions == 'Continental')) +
  ggtitle(waiver(), subtitle = 'Simple Transactions, Continental Cluster') +
  facet_wrap(~ concLabel)
ggsave('pdf/conftime-continental-simple.pdf')

conftimePlot(dSimple %>% filter(regions == 'Global')) +
  ggtitle(waiver(), subtitle = 'Simple Transactions, Global Cluster') +
  facet_wrap(~ concLabel)
ggsave('pdf/conftime-global-simple.pdf')



conftimePlot(dPlutus %>% filter(regions == 'Local')) +
  ggtitle(waiver(), subtitle = 'Plutus Transactions, Local Cluster') +
  facet_wrap(~ concLabel)
ggsave('pdf/conftime-local-plutus.pdf')

conftimePlot(dPlutus %>% filter(regions == 'Continental')) +
  ggtitle(waiver(), subtitle = 'Plutus Transactions, Continental Cluster') +
  facet_wrap(~ concLabel)
ggsave('pdf/conftime-continental-plutus.pdf')

conftimePlot(dPlutus %>% filter(regions == 'Global')) +
  ggtitle(waiver(), subtitle = 'Plutus Transactions, Global Cluster') +
  facet_wrap(~ concLabel)
ggsave('pdf/conftime-global-plutus.pdf')
