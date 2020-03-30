library(tidyverse)
library(sf)

##

places <- st_read("data/places.geojson")

##

library(data.table)
library(dtplyr)

##

week <- fread("data/v1/main-file/2020-03-15-weekly-patterns.csv.gz")

week <- lazy_dt(week)

one <- filter(week, city == "Philadelphia") %>% as_tibble()
two <- filter(week, city == "Philadelphia") %>% as_tibble()
tre <- filter(week, city == "Philadelphia") %>% as_tibble()
fou <- filter(week, city == "Philadelphia") %>% as_tibble()

##

glimpse(one)

##

one_days <- 
  one %>% 
  mutate(visits = str_remove_all(visits_by_day, pattern = "\\[")) %>%
  mutate(visits = str_remove_all(visits, pattern = "\\]")) %>%
  separate(col = visits, sep = ",", into = c("sun", "mon", "tue", "wed", "thu", "fri", "sat")) %>%
  mutate(start = as_date(date_range_start)) %>%
  select(safegraph_place_id, start, sun:sat) %>%
  gather(day, visits, sun:sat) %>%
  mutate(date = case_when(day == "sun" ~ as_date(start) + 0, 
                          day == "mon" ~ as_date(start) + 1, 
                          day == "tue" ~ as_date(start) + 2, 
                          day == "wed" ~ as_date(start) + 3, 
                          day == "thu" ~ as_date(start) + 4, 
                          day == "fri" ~ as_date(start) + 5, 
                          day == "sat" ~ as_date(start) + 6))

unique(one_days$day)

two_days <- 
  two %>% 
  mutate(visits = str_remove_all(visits_by_day, pattern = "\\[")) %>%
  mutate(visits = str_remove_all(visits, pattern = "\\]")) %>%
  separate(col = visits, sep = ",", into = c("sun", "mon", "tue", "wed", "thu", "fri", "sat")) %>%
  mutate(start = as_date(date_range_start)) %>%
  select(safegraph_place_id, start, sun:sat) %>%
  gather(day, visits, sun:sat) %>%
  mutate(date = case_when(day == "sun" ~ as_date(start) + 0, 
                          day == "mon" ~ as_date(start) + 1, 
                          day == "tue" ~ as_date(start) + 2, 
                          day == "wed" ~ as_date(start) + 3, 
                          day == "thu" ~ as_date(start) + 4, 
                          day == "fri" ~ as_date(start) + 5, 
                          day == "sat" ~ as_date(start) + 6))

tre_days <- 
  tre %>% 
  mutate(visits = str_remove_all(visits_by_day, pattern = "\\[")) %>%
  mutate(visits = str_remove_all(visits, pattern = "\\]")) %>%
  separate(col = visits, sep = ",", into = c("sun", "mon", "tue", "wed", "thu", "fri", "sat")) %>%
  mutate(start = as_date(date_range_start)) %>%
  select(safegraph_place_id, start, sun:sat) %>%
  gather(day, visits, sun:sat) %>%
  mutate(date = case_when(day == "sun" ~ as_date(start) + 0, 
                          day == "mon" ~ as_date(start) + 1, 
                          day == "tue" ~ as_date(start) + 2, 
                          day == "wed" ~ as_date(start) + 3, 
                          day == "thu" ~ as_date(start) + 4, 
                          day == "fri" ~ as_date(start) + 5, 
                          day == "sat" ~ as_date(start) + 6))

fou_days <- 
  fou %>% 
  mutate(visits = str_remove_all(visits_by_day, pattern = "\\[")) %>%
  mutate(visits = str_remove_all(visits, pattern = "\\]")) %>%
  separate(col = visits, sep = ",", into = c("sun", "mon", "tue", "wed", "thu", "fri", "sat")) %>%
  mutate(start = as_date(date_range_start)) %>%
  select(safegraph_place_id, start, sun:sat) %>%
  gather(day, visits, sun:sat) %>%
  mutate(date = case_when(day == "sun" ~ as_date(start) + 0, 
                          day == "mon" ~ as_date(start) + 1, 
                          day == "tue" ~ as_date(start) + 2, 
                          day == "wed" ~ as_date(start) + 3, 
                          day == "thu" ~ as_date(start) + 4, 
                          day == "fri" ~ as_date(start) + 5, 
                          day == "sat" ~ as_date(start) + 6))

## 

combined <- bind_rows(one_days, two_days, tre_days)

##

timeseries <-
  combined %>%
  mutate(visits = as.numeric(visits)) %>%
  inner_join(places) %>%
  select(-geometry) %>%
  mutate(chain = if_else(is.na(brands), 0, 1)) %>%
  select(brands, top_category, chain,  date, visits) %>%
  group_by(top_category, chain, date) %>%
  summarise(visits = sum(visits)) %>%
  mutate(visits = scale(visits)) %>%
  ungroup()

ggplot(timeseries %>%
         filter(!str_detect(top_category, "Related")), aes(date, visits, colour = factor(chain))) +
  geom_line(show.legend = FALSE) +
  facet_wrap(~ top_category) +
  theme_hor()

##

library(tigris)
library(sf)

##

options(tigris_use_cache = TRUE)

##

roads <- roads("PA", "Philadelphia", class = 'sf')
tracts <- tracts("PA", "Philadelphia", class = 'sf')

water <- 
  area_water("PA", "Philadelphia", class = 'sf') %>%
  st_union() %>%
  st_combine()

##

projection <- st_crs(roads)

##

library(tidyverse)

##

background <-
  tracts %>%
  mutate(dissolve = 1) %>%
  group_by(dissolve) %>%
  summarise() %>%
  st_difference(water)

##

ggplot() +
  geom_sf(data = background,
          aes(), fill = '#7d7d7d', colour = NA) +
  geom_sf(data = roads,
          aes(), fill = NA, colour = '#ffffff', alpha = 0.5, size = 0.1) +
  theme_bm_legend()

##

library(gganimate)

##

timeseries <-
  combined %>%
  mutate(visits = as.numeric(visits)) %>%
  inner_join(places) %>%
  filter(str_detect(top_category, "Drinking|Eating")) %>%
  st_as_sf() %>%
  select(location_name,  date, visits) %>%
  group_by(location_name) %>%
  mutate(visits = ntile(visits, 100)) %>%
  ungroup()

timeseries <-
  timeseries %>%
  st_coordinates() %>%
  as_tibble() %>%
  bind_cols(timeseries) %>%
  st_as_sf() %>%
  filter(X > -75.3)

##

pal <- read_csv("https://github.com/asrenninger/palettes/raw/master/turbo.txt", col_names = FALSE) %>% pull(X1)

anim <- 
  ggplot(data = timeseries) +
  geom_sf(data = background,
          aes(), fill = '#7d7d7d', colour = NA) +
  geom_sf(data = roads,
          aes(), fill = NA, colour = '#ffffff', alpha = 0.5, size = 0.1) +
  geom_point(aes(x = X, y = Y, colour = visits), size = 0.5) +
  transition_manual(date) +
  ease_aes('linear') +
  labs(title = "{current_frame}",
       subtitle = "FOOTFALL AT RESTAURANTS AND BARS") + 
  scale_colour_gradientn(colours = pal,
                         guide = guide_continuous,
                         name = "visits (percentiles)",
                         breaks = c(25, 50, 75)) +
  theme_bm_legend()

animate(anim, height = 785, width = 700, start_pause = 5, end_pause = 5)
anim_save("test.gif", animation = last_animation())
