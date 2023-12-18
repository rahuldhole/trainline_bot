### Installation

~~~
docker build -t trainline .
~~~

### RUN
~~~
# Create a container
docker run -it --rm -v "$(pwd)":/usr/src/trainline -w /usr/src/trainline trainline

# In irb 
ComTheTrainLine.find('London', 'Paris', DateTime.new(2023, 12, 31, 17, 0, 0))

from = "London"
to = "Paris"
depart_at = DateTime.new(2023, 12, 31, 17, 0, 0)
ComTheTrainLine.find(from, to, depart_at)
~~~

#### Custom execution options
~~~
cttl = ComTheTrainLine.new
cttl.bot('London', 'Paris', DateTime.new(2023, 12, 31, 17, 0, 0))
~~~

