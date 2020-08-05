# Load Data Cube Configuration
import datacube
dc = datacube.Datacube(app = 'my_app')

import numpy as np
import xarray as xr
import datetime
from copy import copy

# Load the data
def progress_cbk(n, n_total):
    print(n.__str__() + "/" + n_total.__str__(), end='\r', flush=True)


def convert_interval(interval):
    s, e = interval

    start = s[0].__str__() + "-" + s[1].__str__() + "-" + s[2].__str__()
    end = e[0].__str__() + "-" + e[1].__str__() + "-" + e[2].__str__()

    return start, end


def threshold_count(da, mask=None):
    def count_not_nans(arr):
        return np.count_nonzero(~np.isnan(arr))

    total_non_cloudy = count_not_nans(da.values) if mask is None else np.sum(mask)

    return dict(total=np.size(da.values),
                total_non_cloudy=total_non_cloudy)


def threshold_percentage(da, mask=None):
    counts = threshold_count(da, mask=mask)
    return 100.0 - counts["total_non_cloudy"] / counts["total"] * 100.0


def cloud_coverage(dataset):
    from datacube.storage import masking  # Import masking capabilities
    from .dc_mosaic import create_median_mosaic

    clean_pixel_mask = masking.make_mask(
        dataset.quality,
        cloud=False,
        radiometric_saturation='none',
        terrain_occlusion=False)

    masked_cloud = dataset.where((dataset != 0) & clean_pixel_mask)

    mosaic = create_median_mosaic(masked_cloud, clean_pixel_mask, no_data=0)
    mosaic = mosaic.expand_dims({'time': 1})

    return threshold_percentage(mosaic.red)


def load_data(latitude, longitude, platform, time, product, output_crs, resolution, measurements, progress_cbk, max_cloud=5.0):
    time_extents = (datetime.datetime.strptime(time[0], "%Y-%m-%d"),
                    datetime.datetime.strptime(time[1], "%Y-%m-%d"))

    time_extents = ([time_extents[0].date().year, time_extents[0].date().month, time_extents[0].date().day],
                    [time_extents[1].date().year, time_extents[1].date().month, time_extents[1].date().day])

    current = time_extents[0]
    end = time_extents[1]
    datepoints = []
    while current[0] < end[0] or (current[0] <= end[0] and current[1] <= end[1]):
        datepoints.append(copy(current))
        if current[1] >= 12:
            current[1] = 1
            current[0] += 1
        else:
            current[1] += 1

    date_intervals = list(zip(datepoints[:-1], datepoints[1:]))
    date_intervals.append((datepoints[-1], end))

    landsat_dataset = None
    for interval in date_intervals:
        print(interval)
        time_extent = convert_interval(interval)

        current_dataset = dc.load(
            latitude=latitude,
            longitude=longitude,
            platform=platform,
            time=time_extent,
            product=product,
            output_crs=output_crs,
            resolution=resolution,
            progress_cbk=progress_cbk,
            measurements=measurements
        )

        if landsat_dataset is None:
            landsat_dataset = current_dataset
        else:
            landsat_dataset = xr.concat([landsat_dataset, current_dataset], dim="time")

        if cloud_coverage(landsat_dataset) < max_cloud:
            print("Cloud coverage is under {}%, stopping early.".format(max_cloud))
            break

    return landsat_dataset

