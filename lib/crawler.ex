defmodule Crawler do
  @base_url "https://iphimmoi.net/category/hoat-hinh/"

  def get() do
    urls = for page <- 1..25, do: get_movie_url_by_page(page)
    urls = List.flatten(urls)
    data =
      urls
      |> get_movie_html_body()
      |> Enum.map(fn(body) ->
        {:ok, document} = Floki.parse_document(body)
        movie_name = get_movie_title(document)
        IO.inspect("Parsing movie name #{movie_name}")
        %{
          title: movie_name,
          link: get_movie_link(document),
          thumnail: get_movie_thumnail(document),
          year: get_movie_year(document),
          number_of_episode: get_number_of_episode(document),
          full_series: get_full_series_status(document),
        }
      end)
      {_, json_data} = JSON.Encoder.encode(%{
        crawled_at: DateTime.to_string(DateTime.utc_now() |> DateTime.add(7 * 60 * 60 , :second)),
        total: length(data),
        items: data
      })
      IO.inspect("Crawled data: #{json_data}")
      write_to_file(json_data)
  end

  @doc """
  Get movie url list in a page
  ## Parameters
    - page_index: Interger that represents the page of website.
  """
  def get_movie_url_by_page(page_index \\ 1) do
    IO.inspect("Get movie url list in page #{page_index}")
    raw_data = Crawler.HttpClient.get(get_url_by_page(page_index))
    {:ok, document} = Floki.parse_document(raw_data)
    data =
      document
      |> Floki.find(".movie-list-index.home-v2 ul.last-film-box>li>.movie-item")
      |> Floki.attribute("href")
    data
  end

  @doc """
  Get url by page index
  ## Parameters
    - page_index: Interger that represents the page of website.
  """
  def get_url_by_page(page_index) do
    if is_integer(page_index) && page_index > 1 do
      @base_url <> "page/#{page_index}/"
    else
      @base_url
    end
  end

  @doc """
  Get movie detail by url
  ## Parameters
    - urls: Array of movie url
  """
  def get_movie_html_body(urls) do
    urls
    |> Enum.map(fn(url) ->
      Crawler.HttpClient.get(url)
    end)
  end

  @doc """
  Get movie title
  """
  def get_movie_title(body) do
    name =
      body
      |> Floki.find(".movie-info .movie-title .title-1")
      |> Floki.text
    name
  end

  @doc """
  Get movie link
  """
  def get_movie_link(body) do
    [head | _] =
      body
      |> Floki.find("#film-content-wrapper>#film-content")
      |> Floki.attribute("data-href")
    head
  end

  @doc """
  Get movie thumnail
  """
  def get_movie_thumnail(body) do
    data =
      body
      |> Floki.find(".movie-info .movie-l-img img")
      |> Floki.attribute("src")
    List.last(data)
  end

  @doc """
  Get movie year
  """
  def get_movie_year(body) do
    year =
      body
      |> Floki.find("[rel=tag]")
      |> Floki.text
    year
  end

  @doc """
  Get number of episode
  """
  def get_number_of_episode(body) do
    episode_list =
      body
      |> get_episode_list()

      if(length(episode_list) > 0) do
        List.first(episode_list)
      else
        nil
      end
  end

  @doc """
  Get full series status
  """
  def get_full_series_status(body) do
    episode_list =
      body
      |> get_episode_list()

    if(length(episode_list) > 1) do
      current_episode = List.first(episode_list)
      total_episode = Enum.at(episode_list, 1)
      if(current_episode == total_episode) do
        true
      else
        false
      end
    else
      false
    end
  end

  @doc """
  Get episode list
  """
  def get_episode_list(body) do
    episode_list =
      body
      |> Floki.find(".movie-info .movie-meta-info .status")
      |> Floki.text
      |> String.split([" ", ",", "/"])
      |> Enum.map(fn(text) ->
        case Integer.parse(text) do
          {value, _} -> value
          :error -> nil
        end
      end)
      |> Enum.filter(fn(number) -> number != nil end)
      episode_list
  end

  def write_to_file(data) do
    file_name = "./crawed_data/crawler_#{:os.system_time}.json"
    case File.write!(file_name, data, [:raw]) do
      :ok ->
        IO.inspect("Write data to file success: #{file_name}")
      {:error, message} ->
        IO.inspect("Write data to file error: #{message}")
        _ ->
        IO.inspect("Write data to file error")
    end
  end


end
