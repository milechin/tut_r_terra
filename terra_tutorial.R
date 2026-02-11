# ------------------------------------------------------#
#                                                       #
#  GIS Using R: terra package                           #
#  Dennis Milechin                                      #
#                                                       #
# ------------------------------------------------------#


# Terra is a replacement for an existing package called raster
# Benefits of terra
#   1. functions are usually more computationally efficient
#   2. lets you work on large raster datasets that are too 
#      large to fit into the main memory.



# Terra homepage: https://rspatial.github.io/terra/index.html

#----------------------------------------#
#  Install required packages          ####
#----------------------------------------#

# Install sf package 
install.packages("terra")
install.packages("spDataLarge", repos = "https://nowosad.r-universe.dev")
install.packages("tidyterra")
install.packages("spData")
install.packages("tidyvers")

#----------------------------------------#
#  Expectations for this tutorial     ####
#----------------------------------------#

# There are many functions in this package, 
# we are unable to cover them all.  List of 
# functions available:
# https://rspatial.github.io/terra/reference/index.html


#----------------------------------------#
#  Let's explore terra                   ####
#----------------------------------------#
library(terra) 
library(spData)
library(spDataLarge)
library(tidyterra)
library(ggplot2)


##############################
# RASTER Loading and Plotting
##############################

raster_filepath = system.file( "raster/nz_elev.tif", package="spDataLarge" )

# First lets look at the meta data, or the header, of the raster data
describe( raster_filepath )

# To load data or create a new raster data set, we
# use the rast() function.
my_rast = rast( raster_filepath )

class( my_rast )

# Let's look at the my_rast object
my_rast

# We can plot the data
plot( my_rast )

# If we have "tidyterra" installed we can use ggplot
ggplot( data=my_rast ) +
  geom_spatraster()

# This doesn't work, we need to specify data in the geom_spatraster()
# function.
ggplot() +
  geom_spatraster( data=my_rast )

###########################
# RASTER Data Exploration
###########################
# We can gets stats on this raster layer using summary function.

summary(my_rast)

?terra::summary

summary(my_rast, size=1000)

# We can also apply other summarizing functions, such as:
# max() - standard deviation
# min() - minimum value
# sum() - maximum value
# range() - min and max value
# Median() - Median value

my_rast_max <- max(my_rast)
my_rast_max

# Take a look at the dimensions, why do we still have several rows and columns?


# We need to use the global() function to return a single value. Otherwise
# the function will be applied to each individual cell in the raster.
global(my_rast, max)

# Now we get an NA value, this suggests there are NA values in the raster
global(my_rast, max, na.rm=TRUE)

# We can try out some other aggregation functions:
global(my_rast, min, na.rm=TRUE)
global(my_rast, sum, na.rm=TRUE)
global(my_rast, range, na.rm=TRUE)


# We can also create common statistics plots of the values
hist(my_rast, maxcell=1000000)
density(my_rast, maxcell=1000000)
boxplot(my_rast, maxcell=1000000)

###########################
# A closer look at rast()
###########################

?rast

# Let's create some raster files from scratch.

# Specify number of columns and rows
rast1 <- rast(
  nrows=10,
  ncols=10,
  vals=runif(100, 0, 800)
) 

rast1

# Notice this defaults to an extent for the entire world.

ggplot() +
  geom_spatraster( data=rast1) +
  geom_sf( data=world ) +
  ggtitle("Rast1")



# Alternatively we can specify a resolution and terra
# will fill in the area with appropriate number of
# columns and rows
rast2 <- rast(
  resolution=c(10,10),
  vals=runif(100, 0, 800)
)

rast2


# Without a constraint on the extent, it will do this for the entire
# world.
ggplot() +
  geom_spatraster( data=rast2) +
  geom_sf( data=world ) +
  ggtitle("Rast2")

# We can constrain it again by specifying extent.
rast3 <- rast(
  resolution=c(10,10),
  xmin=-50,
  ymin=-50,
  xmax=0,
  ymax=0,
  vals=runif(10, 0, 800)
) 

rast3

ggplot() +
  geom_spatraster( data=rast3) +
  geom_sf( data=world ) +
  ggtitle("Rast3")


# We can also extract an extent of an existing object
# that may represent the area of interest, like we did before
# with multi_rast3 object

nz_elev_path <- system.file( "raster/nz_elev.tif", package="spDataLarge" )
nz_elev <- rast(nz_elev_path)
AOI <- ext(nz_elev)

rast4 <- rast(
  nrows=10,
  ncols=10,
  extent=AOI,
  vals=runif(50, 0, 800),
  crs= crs(nz_elev)
)

rast4

# Since the Area of Interest is New Zealand, lets
# plot only the AOI.
x_extent <- c(xmin(rast5), xmax(rast5))
y_extent <- c(ymin(rast5), ymax(rast5))


ggplot() +
  geom_spatraster( data=rast4) +
  geom_sf(data=world, fill=NA, color="orange", linewidth=1) +
  coord_sf( xlim = x_extent, ylim = y_extent) +
  ggtitle("Rast4")


# To save the raster we can use writeRaster()
writeRaster(rast4, "rast4.tif")

# TIF is not the only raster data format.
# We can use gdal() to list supported drivers.

gdal(drivers=TRUE)

?writeRaster


###########################
# Accessing Cell Values
###########################

sample_rast <- rast(
  nrows=10,
  ncols=10,
  vals=1:10,
)

ggplot() +
  geom_spatraster( data=sample_rast)


# You can extract all values using values() function
values(sample_rast)

# Can also use indexing techniques
sample_rast[1,] # Row indexing
sample_rast[2,]
sample_rast[,1] # Column indexing

sample_rast[2:4, 2:4] # Block of values

subset <- sample_rast[2:4, 2:4]

# We can also use cell numbers to extract values
cells <- cellFromRowCol(sample_rast, col=2, row=c(2,3,4))
cells

sample_rast[cells]

# You can also extract xy coordinates from cell numbers:
xy <- xyFromCell(sample_rast, cells)
xy

# You can also extract values based on xy coordinates using extract()
# function
extract(sample_rast, xy)


###########################
# Updating cell values
###########################

# You can update existing cell values with assignment operator
sample_rast[2:4, 2:4] <- 100

sample_rast
values(sample_rast)

ggplot() +
  geom_spatraster( data=sample_rast)

# We can also specify logical conditions on how we want to update 
# the cells.  Here I am setting all cells with value of 100 to "NA"
sample_rast[sample_rast == 100] <- NA

sample_rast
values(sample_rast)

# We can plot this to see a gray box representing NA values.
ggplot() +
  geom_spatraster( data=sample_rast)




###########################
# Plotting Options
###########################

raster_filepath <- system.file( "raster/nz_elev.tif", package="spDataLarge" )
nz_elev <- rast(raster_filepath)

# Let's take a look at the arguments for geom_spatraster
?geom_spatraster

ggplot() +
  geom_spatraster( 
                data=nz_elev, 
                #show.legend = FALSE,
                #maxcell=50
                )

# If we want to adjust the colors we use one
# of the scale fill functions.  Tidyterra provides us with some
# fill functions to use: https://dieghernan.github.io/tidyterra/reference/index.html#scales

# Functions are groups into three categories
#  scale_*_terrain_d(): For discrete values.
#  scale_*_terrain_c(): For continuous values.
#  scale_*_terrain_b(): For binning continuous values.


ggplot() +
  geom_spatraster( data=nz_elev ) +
  scale_fill_terrain_c() +
  theme_bw()

?scale_fill_terrain_c


ggplot() +
  geom_spatraster( data=nz_elev ) +
  scale_fill_hypso_tint_c() +
  theme_bw()

?scale_fill_hypso_tint_c

ggplot() +
  geom_spatraster( data=nz_elev ) +
  scale_fill_hypso_tint_c( 
     palette="arctic",
     #direction=-1,
     #alpha=1,
     #na.value="black",
     #limits=c(0, 4000),
     #breaks=c(0, 1000, 2000, 3000, 4000),
     #guide = guide_colorbar(
     #     direction="horizontal",
     #    title.position = "top",
     #      barwidth = 15
     #  ),
    ) +
   #labs(fill = "elevation (m)") +
   #theme(legend.position = "bottom") +
  theme_bw() 
   


# We can also create contour plots
# Examples from: https://dieghernan.github.io/tidyterra/reference/geom_spat_contour.html
volcanoe_path <- system.file("extdata/volcano2.tif", package = "tidyterra")
r_volc <- rast(volcanoe_path)


ggplot() +
  geom_spatraster_contour( data=r_volc )

# Again we can fine tune things with function attributes
ggplot() +
  geom_spatraster_contour(
    data = r_volc, aes(color = after_stat(level)),
    binwidth = 1,
    linewidth = 0.4
  ) +
  scale_color_gradientn(
    colours = hcl.colors(20, "Inferno"),
    guide = guide_coloursteps()
  ) +
  theme_minimal()

# There is also a fill variation of this function:
ggplot() +
  geom_spatraster_contour_filled(
    data = r_volc, 
    breaks = seq(80, 200, 10)) +
  scale_fill_hypso_d()

# One can also combine both of them in one plot
ggplot() +
  geom_spatraster_contour_filled(
    data = r_volc, breaks = seq(80, 200, 10),
    alpha = .7
  ) +
  geom_spatraster_contour(
    data = r_volc, breaks = seq(80, 200, 2.5),
    color = "grey30",
    linewidth = 0.1
  ) +
  scale_fill_hypso_d()


#################################
# Working with Multi-Band Raster
#################################

# Let's look at a multi raster file
multi_raster_file = system.file("raster/landsat.tif", package = "spDataLarge")

# Let's look at the header for this file.
describe(multi_raster_file)

multi_rast = rast(multi_raster_file)

class(multi_rast)

multi_rast

# Check how many layers exist in the raster file:
nlyr(multi_rast)

# And their names
names(multi_rast)

# Let's run it through the plot
plot(multi_rast)

# Use ggplot
ggplot() +
  geom_spatraster(data=multi_rast)

# Notice by default it will plot all layers at once.
# But the warning message tells us we can plot by
# 1 layer, or to use facet_wrap function.

ggplot() +
  geom_spatraster( data=multi_rast, aes( fill=landsat_1 ))

# We can try facet_wrap next

ggplot() +
  geom_spatraster( data=multi_rast) +
  facet_wrap(~lyr, ncol = 2)


# If we want to extract a specific layer
# we can use the subset() function.  We 
# can use an index value or the name of the layer.

multi_rast3 <- subset(multi_rast, 3)
multi_rast3

multi_rast4 <- subset(multi_rast, "landsat_4")
multi_rast4

# Or we can use the "$" method
multi_rast1 <- multi_rast$landsat_1


# We can also combine layers into one object:
multi_rast341 <- c(multi_rast3, multi_rast4, multi_rast1)
multi_rast341



###########################
# RASTER CRS Transformation
###########################

# The approach to transforming raster data into another CRS
# is more complicated, as described in the link below:
# https://rspatial.org/spatial/6-crs.html#transforming-raster-data




###########################
# Raster Algebra  
###########################

# Let's create a raster with values of 1
rast_val_1 <- rast(
  nrows=5,
  ncols=5,
  vals=1,
  names="layer1"
)

values(rast_val_1)

# Let's create another raster with values of 2
rast_val_2 <- rast(
  nrows=5,
  ncols=5,
  vals=2,
  names="layer2"
)

values(rast_val_2)

# Let's add the the rasters together
rast_result1 <- rast_val_1 + rast_val_2
values(rast_result1)

# We can create more complicated equations
rast_result2 <- rast_val_1 / (rast_val_2 + 100)
values(rast_result2)

# If we have a stack of rasters, we can still apply raster math
rast_stack <- c(rast_val_1, rast_val_2)
rast_stack

rast_rasult3 <- rast_stack$layer1 * 5 + rast_stack$layer2 
values(rast_rasult3)

# We can rename the layer to something more meaningful
names(rast_rasult3) <- "result3"
rast_rasult3



